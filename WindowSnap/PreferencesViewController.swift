import Cocoa
import Carbon

class PreferencesViewController: NSViewController {
    
    private var leftRecorder: HotkeyRecorderView!
    private var rightRecorder: HotkeyRecorderView!
    private var wakeupCheckbox: NSButton!
    private var statusLabel: NSTextField!
    
    weak var snapManager: SnapManager?
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 300))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentSettings()
    }
    
    // MARK: - UI 구성
    
    private func setupUI() {
        // 타이틀
        let titleLabel = makeLabel("WindowSnap 설정", size: 16, bold: true)
        
        // 구분선
        let separator1 = NSBox()
        separator1.boxType = .separator
        
        // ── 핫키 섹션 ──
        let hotkeyTitle = makeLabel("단축키", size: 13, bold: true)
        hotkeyTitle.textColor = .secondaryLabelColor
        
        let leftLabel  = makeLabel("왼쪽 스냅", size: 13)
        let rightLabel = makeLabel("오른쪽 스냅", size: 13)
        
        leftRecorder  = HotkeyRecorderView(config: Settings.shared.leftHotkey)
        rightRecorder = HotkeyRecorderView(config: Settings.shared.rightHotkey)
        
        leftRecorder.onHotkeyChanged  = { [weak self] config in
            Settings.shared.leftHotkey = config
            self?.snapManager?.reloadHotkeys()
        }
        rightRecorder.onHotkeyChanged = { [weak self] config in
            Settings.shared.rightHotkey = config
            self?.snapManager?.reloadHotkeys()
        }
        
        let hintLabel = makeLabel("클릭 후 원하는 단축키를 누르세요. ESC로 취소.", size: 11)
        hintLabel.textColor = .tertiaryLabelColor
        
        // 구분선
        let separator2 = NSBox()
        separator2.boxType = .separator
        
        // ── 일반 섹션 ──
        let generalTitle = makeLabel("일반", size: 13, bold: true)
        generalTitle.textColor = .secondaryLabelColor
        
        wakeupCheckbox = NSButton(checkboxWithTitle: "로그인 시 자동 실행", target: self, action: #selector(wakeupToggled))
        wakeupCheckbox.state = Settings.shared.openOnWakeup ? .on : .off
        
        // 권한 상태
        let accessibilityGranted = AXIsProcessTrusted()
        statusLabel = makeLabel(
            accessibilityGranted ? "✅ 손쉬운 사용 권한 허용됨" : "⚠️ 손쉬운 사용 권한 필요",
            size: 12
        )
        statusLabel.textColor = accessibilityGranted ? .systemGreen : .systemOrange
        
        let permButton = NSButton(title: "시스템 설정에서 권한 허용", target: self, action: #selector(openAccessibilitySettings))
        permButton.bezelStyle = .inline
        permButton.isHidden = accessibilityGranted
        
        // ── 레이아웃 (Auto Layout) ──
        let allViews: [NSView] = [
            titleLabel, separator1,
            hotkeyTitle,
            leftLabel, leftRecorder,
            rightLabel, rightRecorder,
            hintLabel, separator2,
            generalTitle, wakeupCheckbox,
            statusLabel, permButton
        ]
        allViews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        let pad: CGFloat = 24
        let innerPad: CGFloat = 16
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: pad),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            
            // Separator 1
            separator1.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            separator1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            separator1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            
            // Hotkey Section Title
            hotkeyTitle.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: 12),
            hotkeyTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            
            // Left row
            leftLabel.topAnchor.constraint(equalTo: hotkeyTitle.bottomAnchor, constant: 10),
            leftLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            leftLabel.widthAnchor.constraint(equalToConstant: 90),
            leftRecorder.centerYAnchor.constraint(equalTo: leftLabel.centerYAnchor),
            leftRecorder.leadingAnchor.constraint(equalTo: leftLabel.trailingAnchor, constant: 8),
            leftRecorder.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            
            // Right row
            rightLabel.topAnchor.constraint(equalTo: leftLabel.bottomAnchor, constant: 10),
            rightLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            rightLabel.widthAnchor.constraint(equalToConstant: 90),
            rightRecorder.centerYAnchor.constraint(equalTo: rightLabel.centerYAnchor),
            rightRecorder.leadingAnchor.constraint(equalTo: rightLabel.trailingAnchor, constant: 8),
            rightRecorder.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            
            // Hint
            hintLabel.topAnchor.constraint(equalTo: rightLabel.bottomAnchor, constant: 6),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            
            // Separator 2
            separator2.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 12),
            separator2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            separator2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            
            // General Section Title
            generalTitle.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 12),
            generalTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            
            // Wakeup checkbox
            wakeupCheckbox.topAnchor.constraint(equalTo: generalTitle.bottomAnchor, constant: 10),
            wakeupCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: wakeupCheckbox.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            
            // Permission button
            permButton.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            permButton.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 8),
        ])
    }
    
    private func makeLabel(_ text: String, size: CGFloat, bold: Bool = false) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        return label
    }
    
    // MARK: - Actions
    
    @objc private func wakeupToggled() {
        Settings.shared.openOnWakeup = (wakeupCheckbox.state == .on)
    }
    
    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func loadCurrentSettings() {
        leftRecorder.hotkeyConfig  = Settings.shared.leftHotkey
        rightRecorder.hotkeyConfig = Settings.shared.rightHotkey
        wakeupCheckbox.state = Settings.shared.openOnWakeup ? .on : .off
    }
    
    // 설정창이 다시 보일 때 권한 상태 갱신
    override func viewWillAppear() {
        super.viewWillAppear()
        let granted = AXIsProcessTrusted()
        statusLabel.stringValue = granted ? "✅ 손쉬운 사용 권한 허용됨" : "⚠️ 손쉬운 사용 권한 필요"
        statusLabel.textColor = granted ? .systemGreen : .systemOrange
    }
}
