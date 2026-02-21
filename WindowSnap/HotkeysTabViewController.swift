import Cocoa

class HotkeysTabViewController: NSViewController {

    weak var snapManager: SnapManager?
    private var leftRecorder: HotkeyRecorderView!
    private var rightRecorder: HotkeyRecorderView!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 280))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        let pad: CGFloat = 28

        let sectionLabel = makeLabel("스냅 단축키", size: 12, bold: true)
        sectionLabel.textColor = .secondaryLabelColor
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sectionLabel)

        // 왼쪽 스냅
        let leftLabel = makeLabel("왼쪽 스냅", size: 13)
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leftLabel)

        leftRecorder = HotkeyRecorderView(config: Settings.shared.leftHotkey)
        leftRecorder.translatesAutoresizingMaskIntoConstraints = false
        leftRecorder.onHotkeyChanged = { [weak self] config in
            Settings.shared.leftHotkey = config
            self?.snapManager?.reloadHotkeys()
        }
        view.addSubview(leftRecorder)

        // 오른쪽 스냅
        let rightLabel = makeLabel("오른쪽 스냅", size: 13)
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rightLabel)

        rightRecorder = HotkeyRecorderView(config: Settings.shared.rightHotkey)
        rightRecorder.translatesAutoresizingMaskIntoConstraints = false
        rightRecorder.onHotkeyChanged = { [weak self] config in
            Settings.shared.rightHotkey = config
            self?.snapManager?.reloadHotkeys()
        }
        view.addSubview(rightRecorder)

        // 힌트
        let hint = makeLabel("레코더를 클릭한 후 원하는 키 조합을 누르세요. ESC로 취소, ↺ 버튼으로 기본값 복원.", size: 11)
        hint.textColor = .tertiaryLabelColor
        hint.translatesAutoresizingMaskIntoConstraints = false
        hint.lineBreakMode = .byWordWrapping
        hint.maximumNumberOfLines = 2
        view.addSubview(hint)

        let labelWidth: CGFloat = 90

        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 58),
            sectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            // 왼쪽 스냅 행
            leftLabel.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 14),
            leftLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            leftLabel.widthAnchor.constraint(equalToConstant: labelWidth),
            leftRecorder.centerYAnchor.constraint(equalTo: leftLabel.centerYAnchor),
            leftRecorder.leadingAnchor.constraint(equalTo: leftLabel.trailingAnchor, constant: 12),
            leftRecorder.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            // 오른쪽 스냅 행
            rightLabel.topAnchor.constraint(equalTo: leftLabel.bottomAnchor, constant: 16),
            rightLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            rightLabel.widthAnchor.constraint(equalToConstant: labelWidth),
            rightRecorder.centerYAnchor.constraint(equalTo: rightLabel.centerYAnchor),
            rightRecorder.leadingAnchor.constraint(equalTo: rightLabel.trailingAnchor, constant: 12),
            rightRecorder.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            // 힌트
            hint.topAnchor.constraint(equalTo: rightLabel.bottomAnchor, constant: 16),
            hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
        ])
    }

    private func makeLabel(_ text: String, size: CGFloat, bold: Bool = false) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        return l
    }
}
