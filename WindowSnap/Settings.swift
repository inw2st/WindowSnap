import Cocoa
import Carbon
import ServiceManagement

struct HotkeyConfig: Codable {
    var keyCode: Int
    var modifiers: Int

    static let defaultLeft  = HotkeyConfig(keyCode: kVK_LeftArrow,  modifiers: cmdKey | optionKey)
    static let defaultRight = HotkeyConfig(keyCode: kVK_RightArrow, modifiers: cmdKey | optionKey)

    var displayString: String {
        var s = ""
        if modifiers & controlKey != 0 { s += "⌃" }
        if modifiers & optionKey  != 0 { s += "⌥" }
        if modifiers & shiftKey   != 0 { s += "⇧" }
        if modifiers & cmdKey     != 0 { s += "⌘" }
        s += keyCodeToString(keyCode)
        return s
    }

    private func keyCodeToString(_ code: Int) -> String {
        switch code {
        case kVK_LeftArrow:  return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow:    return "↑"
        case kVK_DownArrow:  return "↓"
        case kVK_Return:     return "↩"
        case kVK_Tab:        return "⇥"
        case kVK_Space:      return "Space"
        case kVK_Delete:     return "⌫"
        case kVK_Escape:     return "⎋"
        default:
            if let c = keyCodeToChar(code) { return c.uppercased() }
            return "(\(code))"
        }
    }

    private func keyCodeToChar(_ keyCode: Int) -> String? {
        let src = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutData = TISGetInputSourceProperty(src, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        let layout = unsafeBitCast(layoutData, to: CFData.self)
        let layoutPtr = unsafeBitCast(CFDataGetBytePtr(layout), to: UnsafePointer<CoreServices.UCKeyboardLayout>.self)
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        UCKeyTranslate(layoutPtr, UInt16(keyCode), UInt16(kUCKeyActionDown), 0, UInt32(LMGetKbdType()), 0, &deadKeyState, 4, &length, &chars)
        if length == 0 { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }
}

class Settings {
    static let shared = Settings()
    private init() {}
    private let defaults = UserDefaults.standard

    private enum Key {
        static let openOnWakeup      = "openOnWakeup"
        static let leftHotkey        = "leftHotkey"
        static let rightHotkey       = "rightHotkey"
        static let animationEnabled  = "animationEnabled"
        static let animationDuration = "animationDuration"
        static let animationSteps    = "animationSteps"
    }

    // MARK: - General
    var openOnWakeup: Bool {
        get { defaults.bool(forKey: Key.openOnWakeup) }
        set { defaults.set(newValue, forKey: Key.openOnWakeup); applyLoginItem(enabled: newValue) }
    }

    // MARK: - Hotkeys
    var leftHotkey: HotkeyConfig {
        get {
            guard let data = defaults.data(forKey: Key.leftHotkey),
                  let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data)
            else { return .defaultLeft }
            return config
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: Key.leftHotkey) }
        }
    }

    var rightHotkey: HotkeyConfig {
        get {
            guard let data = defaults.data(forKey: Key.rightHotkey),
                  let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data)
            else { return .defaultRight }
            return config
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: Key.rightHotkey) }
        }
    }

    // MARK: - Animation
    var animationEnabled: Bool {
        get { defaults.object(forKey: Key.animationEnabled) == nil ? true : defaults.bool(forKey: Key.animationEnabled) }
        set { defaults.set(newValue, forKey: Key.animationEnabled) }
    }

    var animationDuration: Double {
        get { defaults.object(forKey: Key.animationDuration) == nil ? 0.13 : defaults.double(forKey: Key.animationDuration) }
        set { defaults.set(newValue, forKey: Key.animationDuration) }
    }

    var animationSteps: Int {
        get { defaults.object(forKey: Key.animationSteps) == nil ? 12 : defaults.integer(forKey: Key.animationSteps) }
        set { defaults.set(newValue, forKey: Key.animationSteps) }
    }

    // MARK: - Login Item
    private func applyLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    if service.status != .enabled { try service.register() }
                } else {
                    if service.status == .enabled { try service.unregister() }
                }
            } catch { print("Login item error: \(error)") }
        }
    }
}
