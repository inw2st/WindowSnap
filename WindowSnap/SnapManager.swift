import Cocoa
import Carbon

@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError

// 스냅 상태를 추적하는 열거형
enum SnapState {
    case none
    case left
    case right
}

class SnapManager {
    private var windowObservers: [CGWindowID: AXObserver] = [:]
    private var isRestoringFromDrag = false
    
    private let hotkeyLeftID:  UInt32 = 1
    private let hotkeyRightID: UInt32 = 2
    
    private var hotkeyLeftRef:  EventHotKeyRef?
    private var hotkeyRightRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    // 창별 스냅 상태: [windowID: (state, originalFrame)]
    private var windowStates: [CGWindowID: (state: SnapState, originalFrame: CGRect)] = [:]
    
    private var selfPtr: UnsafeMutableRawPointer?
    
    // MARK: - 핫키 등록
    
    func registerHotkeys() {
        if selfPtr == nil {
            selfPtr = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            InstallEventHandler(
                GetApplicationEventTarget(),
                { (_, event, userData) -> OSStatus in
                    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                    let manager = Unmanaged<SnapManager>.fromOpaque(userData).takeUnretainedValue()
                    return manager.handleHotKeyEvent(event!)
                },
                1, &eventType, selfPtr, &eventHandlerRef
            )
        }
        registerKeys()
        startMouseDragDetection()
    }
    
    /// 설정 변경 후 핫키 재등록
    func reloadHotkeys() {
        unregisterKeys()
        registerKeys()
    }
    
    private func registerKeys() {
        let left  = Settings.shared.leftHotkey
        let right = Settings.shared.rightHotkey
        var leftID  = EventHotKeyID(signature: OSType(0x574E4C54), id: hotkeyLeftID)
        var rightID = EventHotKeyID(signature: OSType(0x574E5254), id: hotkeyRightID)
        RegisterEventHotKey(UInt32(left.keyCode),  UInt32(left.modifiers),  leftID,  GetApplicationEventTarget(), 0, &hotkeyLeftRef)
        RegisterEventHotKey(UInt32(right.keyCode), UInt32(right.modifiers), rightID, GetApplicationEventTarget(), 0, &hotkeyRightRef)
        print("✅ 핫키: \(left.displayString) ← / \(right.displayString) →")
    }
    
    private func unregisterKeys() {
        if let ref = hotkeyLeftRef  { UnregisterEventHotKey(ref); hotkeyLeftRef  = nil }
        if let ref = hotkeyRightRef { UnregisterEventHotKey(ref); hotkeyRightRef = nil }
    }
    
    func unregisterHotkeys() {
        unregisterKeys()
        if let ref = eventHandlerRef { RemoveEventHandler(ref); eventHandlerRef = nil }
        if let ptr = selfPtr { Unmanaged<SnapManager>.fromOpaque(ptr).release(); selfPtr = nil }
    }
    
    // MARK: - 드래그 감지

    private func startMouseDragDetection() {
        // 전역 마우스 드래그 감지
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            self?.handleMouseDragged(event: event)
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleMouseUp(event: event)
        }
    }

    private var isDragging = false
    private var dragWindowID: CGWindowID?

    private func handleMouseDragged(event: NSEvent) {
        guard !isDragging else { return }
        guard let window = getFrontmostWindow() else { return }
        let windowID = window.windowID
        guard let entry = windowStates[windowID], entry.state != .none else { return }
        
        isDragging = true
        dragWindowID = windowID
        
        isRestoringFromDrag = true
        defer { isRestoringFromDrag = false }
        
        let currentFrame = getWindowFrame(window: window)
        let originalFrame = entry.originalFrame
        let mouseX = NSEvent.mouseLocation.x
        
        // 현재 스냅된 창에서 마우스의 X 비율 계산 (0.0 ~ 1.0)
        let ratioX = (mouseX - currentFrame.origin.x) / currentFrame.width
        
        // 원래 크기로 복구 시 같은 비율 위치에 마우스가 오도록 X 계산
        let targetX = mouseX - originalFrame.width * ratioX
        
        // 화면 밖으로 나가지 않게 클램핑
        var clampedX = targetX
        if let screen = NSScreen.main {
            let screenFrame = flipRect(screen.visibleFrame)
            clampedX = max(screenFrame.minX, min(targetX, screenFrame.maxX - originalFrame.width))
        }
        
        let restoredFrame = CGRect(
            x: clampedX,
            y: currentFrame.origin.y,
            width: originalFrame.width,
            height: originalFrame.height
        )

        applyFrame(restoredFrame, to: window.element)
        windowStates[windowID] = (.none, originalFrame)
    }

    private func handleMouseUp(event: NSEvent) {
        isDragging = false
        dragWindowID = nil
    }

    // MARK: - 이벤트 처리
    
    private func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
        var hotkeyID = EventHotKeyID()
        GetEventParameter(event, EventParamName(kEventParamDirectObject),
                          EventParamType(typeEventHotKeyID), nil,
                          MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
        switch hotkeyID.id {
        case hotkeyLeftID:  handleSnap(direction: .left)
        case hotkeyRightID: handleSnap(direction: .right)
        default: break
        }
        return noErr
    }
    
    // MARK: - 스냅 로직
    
    private func handleSnap(direction: SnapState) {
        guard !isRestoringFromDrag else { return }
        guard let window = getFrontmostWindow() else { return }
        let windowID     = window.windowID
        let currentEntry = windowStates[windowID]
        let currentState = currentEntry?.state ?? .none
        let savedFrame   = currentEntry?.originalFrame
        
        switch direction {
        case .left:
            if currentState == .left { return }
            else if currentState == .right {
                if let frame = savedFrame { setWindowFrame(window: window, frame: frame); windowStates[windowID] = (.none, frame) }
            } else {
                let original = getWindowFrame(window: window)
                setWindowFrame(window: window, frame: leftHalfFrame(for: window))
                windowStates[windowID] = (.left, original)
            }
        case .right:
            if currentState == .right { return }
            else if currentState == .left {
                if let frame = savedFrame { setWindowFrame(window: window, frame: frame); windowStates[windowID] = (.none, frame) }
            } else {
                let original = getWindowFrame(window: window)
                setWindowFrame(window: window, frame: rightHalfFrame(for: window))
                windowStates[windowID] = (.right, original)
            }
        case .none: break
        }
    }
    
    // MARK: - Accessibility API
    
    private func getFrontmostWindow() -> (element: AXUIElement, windowID: CGWindowID)? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        var windowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue) == .success else { return nil }
        let axWindow = windowValue as! AXUIElement
        var windowID: CGWindowID = 0
        _AXUIElementGetWindow(axWindow, &windowID)
        return (element: axWindow, windowID: windowID)
    }
    
    private func getWindowFrame(window: (element: AXUIElement, windowID: CGWindowID)) -> CGRect {
        var pv: CFTypeRef?; var sv: CFTypeRef?
        AXUIElementCopyAttributeValue(window.element, kAXPositionAttribute as CFString, &pv)
        AXUIElementCopyAttributeValue(window.element, kAXSizeAttribute     as CFString, &sv)
        var pos = CGPoint.zero; var size = CGSize.zero
        if let p = pv { AXValueGetValue(p as! AXValue, .cgPoint, &pos) }
        if let s = sv { AXValueGetValue(s as! AXValue, .cgSize,  &size) }
        return CGRect(origin: pos, size: size)
    }
    
    // 진행 중인 애니메이션 취소용
    private var currentDisplayLink: CADisplayLink?
    private func setWindowFrame(window: (element: AXUIElement, windowID: CGWindowID), frame: CGRect) {
        guard Settings.shared.animationEnabled else {
            applyFrame(frame, to: window.element)
            return
        }

        // 이전 애니메이션 중단
        currentDisplayLink?.invalidate()
        currentDisplayLink = nil

        let duration   = Settings.shared.animationDuration
        let startFrame = getWindowFrame(window: window)
        let startTime  = CACurrentMediaTime()
        let element    = window.element

        guard let screen = NSScreen.main else {
            applyFrame(frame, to: element)
            return
        }

        var link: CADisplayLink?

        let handler = DisplayLinkHandler(
            startFrame: startFrame,
            targetFrame: frame,
            startTime: startTime,
            duration: duration,
            element: element
        ) { [weak self] in
            link?.invalidate()
            self?.currentDisplayLink = nil
        }

        let displayLink = screen.displayLink(target: handler, selector: #selector(DisplayLinkHandler.tick(_:)))
        // AX API가 120fps를 따라가지 못해 오히려 버벅이므로 60fps로 고정
        if #available(macOS 14.0, *) {
            displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        }
        displayLink.add(to: .main, forMode: .common)
        link = displayLink
        currentDisplayLink = displayLink
    }

    private func applyFrame(_ frame: CGRect, to element: AXUIElement) {
        var pos  = frame.origin
        var size = frame.size
        if let pv = AXValueCreate(.cgPoint, &pos)  { AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, pv) }
        if let sv = AXValueCreate(.cgSize,  &size)  { AXUIElementSetAttributeValue(element, kAXSizeAttribute     as CFString, sv) }
    }

    private func screenForWindow(_ window: (element: AXUIElement, windowID: CGWindowID)) -> NSScreen {
        let center = CGPoint(x: getWindowFrame(window: window).midX, y: getWindowFrame(window: window).midY)
        return NSScreen.screens.first(where: { flipRect($0.frame).contains(center) }) ?? NSScreen.main ?? NSScreen.screens[0]
    }
    
    private func leftHalfFrame(for window: (element: AXUIElement, windowID: CGWindowID)) -> CGRect {
        let vf = flipRect(screenForWindow(window).visibleFrame)
        return CGRect(x: vf.minX, y: vf.minY, width: vf.width / 2, height: vf.height)
    }
    
    private func rightHalfFrame(for window: (element: AXUIElement, windowID: CGWindowID)) -> CGRect {
        let vf = flipRect(screenForWindow(window).visibleFrame)
        return CGRect(x: vf.midX, y: vf.minY, width: vf.width / 2, height: vf.height)
    }
    
    private func flipRect(_ rect: CGRect) -> CGRect {
        let h = NSScreen.screens.first?.frame.height ?? 0
        return CGRect(x: rect.minX, y: h - rect.maxY, width: rect.width, height: rect.height)
    }
}

class DisplayLinkHandler: NSObject {
    private let startFrame:  CGRect
    private let targetFrame: CGRect
    private let startTime:   CFTimeInterval
    private let duration:    Double
    private let element:     AXUIElement
    private let onFinished:  () -> Void

    init(startFrame: CGRect, targetFrame: CGRect, startTime: CFTimeInterval,
         duration: Double, element: AXUIElement, onFinished: @escaping () -> Void) {
        self.startFrame  = startFrame
        self.targetFrame = targetFrame
        self.startTime   = startTime
        self.duration    = duration
        self.element     = element
        self.onFinished  = onFinished
    }

    @objc func tick(_ link: CADisplayLink) {
        let elapsed = CACurrentMediaTime() - startTime
        let raw = min(elapsed / duration, 1.0)

        // ease-out quart: 빠르게 시작해서 목표 위치에 딱 맞아떨어짐
        let t: Double = 1 - pow(1 - raw, 4)

        let s = startFrame
        let g = targetFrame
        var pos  = CGPoint(x: s.origin.x + (g.origin.x - s.origin.x) * t,
                           y: s.origin.y + (g.origin.y - s.origin.y) * t)
        var size = CGSize (width:  s.size.width  + (g.size.width  - s.size.width)  * t,
                           height: s.size.height + (g.size.height - s.size.height) * t)

        if let pv = AXValueCreate(.cgPoint, &pos)  { AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, pv) }
        if let sv = AXValueCreate(.cgSize,  &size)  { AXUIElementSetAttributeValue(element, kAXSizeAttribute     as CFString, sv) }

        if raw >= 1.0 {
            // 미세한 오차 방지: 최종 위치를 정확하게 한 번 더 고정
            var finalPos  = targetFrame.origin
            var finalSize = targetFrame.size
            if let pv = AXValueCreate(.cgPoint, &finalPos)  { AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, pv) }
            if let sv = AXValueCreate(.cgSize,  &finalSize) { AXUIElementSetAttributeValue(element, kAXSizeAttribute     as CFString, sv) }
            onFinished()
        }
    }
}
