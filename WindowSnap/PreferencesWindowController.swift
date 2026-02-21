import Cocoa

class PreferencesWindowController: NSWindowController, NSToolbarDelegate {

    private weak var snapManager: SnapManager?
    private var generalVC: GeneralTabViewController!
    private var hotkeysVC: HotkeysTabViewController!
    private var animationVC: AnimationTabViewController!
    private var toolbar: NSToolbar!

    private enum TabID: String {
        case general   = "General"
        case hotkeys   = "Hotkeys"
        case animation = "Animation"
    }
    private var currentTab: TabID = .general

    convenience init(snapManager: SnapManager) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "환경설정"
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
        self.snapManager = snapManager
        setupViewControllers()
        setupToolbar()
        switchTab(.general)
    }

    private func setupViewControllers() {
        generalVC   = GeneralTabViewController()
        hotkeysVC   = HotkeysTabViewController()
        hotkeysVC.snapManager = snapManager
        animationVC = AnimationTabViewController()
    }

    private func setupToolbar() {
        toolbar = NSToolbar(identifier: "PreferencesToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconAndLabel
        toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(TabID.general.rawValue)
        window?.toolbar = toolbar
    }

    // MARK: - NSToolbarDelegate

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.init(TabID.general.rawValue), .init(TabID.hotkeys.rawValue), .init(TabID.animation.rawValue)]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.init(TabID.general.rawValue), .init(TabID.hotkeys.rawValue), .init(TabID.animation.rawValue)]
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        switch itemIdentifier.rawValue {
        case TabID.general.rawValue:
            item.label = "일반"
            item.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "일반")
            item.action = #selector(showGeneral)
            item.target = self
        case TabID.hotkeys.rawValue:
            item.label = "단축키"
            item.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "단축키")
            item.action = #selector(showHotkeys)
            item.target = self
        case TabID.animation.rawValue:
            item.label = "애니메이션"
            item.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "애니메이션")
            item.action = #selector(showAnimation)
            item.target = self
        default:
            return nil
        }
        return item
    }

    // MARK: - Tab switching

    @objc private func showGeneral()   { switchTab(.general) }
    @objc private func showHotkeys()   { switchTab(.hotkeys) }
    @objc private func showAnimation() { switchTab(.animation) }

    private func switchTab(_ tab: TabID) {
        currentTab = tab
        toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(tab.rawValue)

        let vc: NSViewController
        switch tab {
        case .general:   vc = generalVC
        case .hotkeys:   vc = hotkeysVC
        case .animation: vc = animationVC
        }

        // 창 크기 애니메이션
        let newSize = vc.view.frame.size
        var frame = window!.frame
        let oldContentHeight = window!.contentRect(forFrameRect: frame).height
        frame.origin.y += oldContentHeight - newSize.height
        frame.size.width = newSize.width
        frame.size.height = window!.frameRect(forContentRect: CGRect(origin: .zero, size: newSize)).height

        window?.contentViewController = vc
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            window?.animator().setFrame(frame, display: true)
        }
    }

    func showAndFocus() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
