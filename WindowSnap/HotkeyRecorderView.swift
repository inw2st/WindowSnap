import Cocoa
import Carbon

class HotkeyRecorderView: NSView {

    var hotkeyConfig: HotkeyConfig {
        didSet { updateLabel() }
    }
    var onHotkeyChanged: ((HotkeyConfig) -> Void)?

    private var isRecording = false
    private let label = NSTextField(labelWithString: "")
    private let resetButton = NSButton()
    private var localMonitor: Any?
    private var flagsMonitor: Any?
    private let defaultConfig: HotkeyConfig

    init(config: HotkeyConfig) {
        self.hotkeyConfig = config
        self.defaultConfig = config
        super.init(frame: .zero)
        setupUI()
        updateLabel()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 7
        layer?.borderWidth = 1.5
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        label.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        resetButton.image = NSImage(systemSymbolName: "arrow.counterclockwise", accessibilityDescription: "Reset")
        resetButton.imagePosition = .imageOnly
        resetButton.bezelStyle = .inline
        resetButton.isBordered = false
        resetButton.contentTintColor = .tertiaryLabelColor
        resetButton.toolTip = "기본값으로 재설정"
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.target = self
        resetButton.action = #selector(resetHotkey)
        addSubview(resetButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 32),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(equalTo: resetButton.leadingAnchor, constant: -4),
            resetButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            resetButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 16),
        ])
    }

    private func updateLabel() {
        if isRecording {
            label.stringValue = "단축키를 입력하세요..."
            label.textColor = .secondaryLabelColor
        } else {
            label.stringValue = hotkeyConfig.displayString
            label.textColor = .labelColor
        }
    }

    override func mouseDown(with event: NSEvent) {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
        label.stringValue = "단축키를 입력하세요..."
        label.textColor = .secondaryLabelColor

        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event)
            return event
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event: event)
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        updateLabel()
        if let m = flagsMonitor { NSEvent.removeMonitor(m); flagsMonitor = nil }
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
    }

    private func handleFlagsChanged(event: NSEvent) {
        guard isRecording else { return }
        let mods = carbonModifiers(from: event.modifierFlags)
        if mods == 0 {
            label.stringValue = "단축키를 입력하세요..."
            label.textColor = .secondaryLabelColor
        } else {
            label.stringValue = modifierString(mods) + "..."
            label.textColor = .controlAccentColor
        }
    }

    private func handleKeyDown(event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) { stopRecording(); return }
        let soloMods: [UInt16] = [
            UInt16(kVK_Command), UInt16(kVK_Option), UInt16(kVK_Control), UInt16(kVK_Shift),
            UInt16(kVK_RightCommand), UInt16(kVK_RightOption), UInt16(kVK_RightControl), UInt16(kVK_RightShift)
        ]
        if soloMods.contains(event.keyCode) { return }
        let mods = carbonModifiers(from: event.modifierFlags)
        if mods == 0 { return }
        let newConfig = HotkeyConfig(keyCode: Int(event.keyCode), modifiers: mods)
        hotkeyConfig = newConfig
        onHotkeyChanged?(newConfig)
        stopRecording()
    }

    @objc private func resetHotkey() {
        hotkeyConfig = defaultConfig
        onHotkeyChanged?(defaultConfig)
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var mods = 0
        if flags.contains(.command) { mods |= cmdKey }
        if flags.contains(.option)  { mods |= optionKey }
        if flags.contains(.control) { mods |= controlKey }
        if flags.contains(.shift)   { mods |= shiftKey }
        return mods
    }

    private func modifierString(_ mods: Int) -> String {
        var s = ""
        if mods & controlKey != 0 { s += "⌃" }
        if mods & optionKey  != 0 { s += "⌥" }
        if mods & shiftKey   != 0 { s += "⇧" }
        if mods & cmdKey     != 0 { s += "⌘" }
        return s
    }

    override var acceptsFirstResponder: Bool { true }
}
