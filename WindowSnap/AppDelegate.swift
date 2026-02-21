import Cocoa
import ServiceManagement

// AppDelegate.swift 맨 위에
nonisolated(unsafe) let appDelegate = AppDelegate()

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    var snapManager: SnapManager!
    var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        snapManager = SnapManager()
        snapManager.registerHotkeys()
        setupMenuBar()
        requestAccessibilityIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        snapManager.unregisterHotkeys()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: 44)
        if let button = statusItem?.button {
            button.title = "📐"
        }
        buildMenu()
    }

    func buildMenu() {
        let menu = NSMenu()
        let titleItem = NSMenuItem(title: "WindowSnap", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())
        let leftItem = NSMenuItem(title: "\(Settings.shared.leftHotkey.displayString)  왼쪽 스냅", action: nil, keyEquivalent: "")
        leftItem.isEnabled = false
        menu.addItem(leftItem)
        let rightItem = NSMenuItem(title: "\(Settings.shared.rightHotkey.displayString)  오른쪽 스냅", action: nil, keyEquivalent: "")
        rightItem.isEnabled = false
        menu.addItem(rightItem)
        menu.addItem(.separator())
        let prefItem = NSMenuItem(title: "설정...", action: #selector(openPreferences), keyEquivalent: ",")
        prefItem.target = self
        menu.addItem(prefItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        statusItem?.menu = menu
    }

    @objc func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(snapManager: snapManager)
        }
        preferencesWindowController?.showAndFocus()
        buildMenu()
    }

    private func requestAccessibilityIfNeeded() {
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
    }
}
