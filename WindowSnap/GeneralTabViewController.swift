import Cocoa

class GeneralTabViewController: NSViewController {

    private var wakeupCheckbox: NSButton!
    private var statusLabel: NSTextField!
    private var permButton: NSButton!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 280))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        let pad: CGFloat = 28

        // 로그인 시 자동 실행
        wakeupCheckbox = NSButton(checkboxWithTitle: "로그인 시 자동 실행", target: self, action: #selector(wakeupToggled))
        wakeupCheckbox.state = Settings.shared.openOnWakeup ? .on : .off
        wakeupCheckbox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wakeupCheckbox)

        // 손쉬운 사용 섹션
        let accessTitle = makeLabel("손쉬운 사용 권한", size: 12, bold: true)
        accessTitle.textColor = .secondaryLabelColor
        accessTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(accessTitle)

        let accessGranted = AXIsProcessTrusted()
        statusLabel = makeLabel(
            accessGranted ? "✅  권한이 허용되어 있습니다" : "⚠️  권한이 필요합니다",
            size: 13
        )
        statusLabel.textColor = accessGranted ? .systemGreen : .systemOrange
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        permButton = NSButton(title: "시스템 설정 열기", target: self, action: #selector(openAccessibilitySettings))
        permButton.bezelStyle = .rounded
        permButton.isHidden = accessGranted
        permButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(permButton)

        let sep = NSBox(); sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sep)

        NSLayoutConstraint.activate([
            wakeupCheckbox.topAnchor.constraint(equalTo: view.topAnchor, constant: pad),
            wakeupCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            sep.topAnchor.constraint(equalTo: wakeupCheckbox.bottomAnchor, constant: 20),
            sep.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            sep.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            accessTitle.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 16),
            accessTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            statusLabel.topAnchor.constraint(equalTo: accessTitle.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            permButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            permButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
        ])
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        let granted = AXIsProcessTrusted()
        statusLabel.stringValue = granted ? "✅  권한이 허용되어 있습니다" : "⚠️  권한이 필요합니다"
        statusLabel.textColor = granted ? .systemGreen : .systemOrange
        permButton.isHidden = granted
    }

    @objc private func wakeupToggled() {
        Settings.shared.openOnWakeup = (wakeupCheckbox.state == .on)
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func makeLabel(_ text: String, size: CGFloat, bold: Bool = false) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        return l
    }
}
