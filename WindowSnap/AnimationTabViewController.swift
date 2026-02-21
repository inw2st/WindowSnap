import Cocoa

class AnimationTabViewController: NSViewController {

    private var enabledCheckbox: NSButton!
    private var durationSlider: NSSlider!
    private var durationLabel: NSTextField!
    private var stepsSlider: NSSlider!
    private var stepsLabel: NSTextField!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 280))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        let pad: CGFloat = 28

        // ── 애니메이션 On/Off ──
        let sectionLabel = makeLabel("애니메이션", size: 12, bold: true)
        sectionLabel.textColor = .secondaryLabelColor
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sectionLabel)

        enabledCheckbox = NSButton(checkboxWithTitle: "스냅 애니메이션 활성화", target: self, action: #selector(enabledToggled))
        enabledCheckbox.state = Settings.shared.animationEnabled ? .on : .off
        enabledCheckbox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(enabledCheckbox)

        let sep = NSBox(); sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sep)

        // ── 속도 조절 ──
        let speedTitle = makeLabel("속도 조절", size: 12, bold: true)
        speedTitle.textColor = .secondaryLabelColor
        speedTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedTitle)

        let durationTitleLabel = makeLabel("지속 시간", size: 13)
        durationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(durationTitleLabel)

        durationSlider = NSSlider(value: Settings.shared.animationDuration,
                                  minValue: 0.08, maxValue: 0.5,
                                  target: self, action: #selector(durationChanged))
        durationSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(durationSlider)

        durationLabel = makeLabel("\(String(format: "%.2f", Settings.shared.animationDuration))초", size: 12)
        durationLabel.textColor = .secondaryLabelColor
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(durationLabel)

        let stepsTitleLabel = makeLabel("부드러움", size: 13)
        stepsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepsTitleLabel)

        stepsSlider = NSSlider(value: Double(Settings.shared.animationSteps),
                               minValue: 4, maxValue: 30,
                               target: self, action: #selector(stepsChanged))
        stepsSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepsSlider)

        stepsLabel = makeLabel("\(Settings.shared.animationSteps) 단계", size: 12)
        stepsLabel.textColor = .secondaryLabelColor
        stepsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepsLabel)

        let labelW: CGFloat = 70
        let labelValW: CGFloat = 50

        NSLayoutConstraint.activate([
            // 섹션 타이틀
            sectionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 58),
            sectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            // 체크박스
            enabledCheckbox.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 10),
            enabledCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            // 구분선
            sep.topAnchor.constraint(equalTo: enabledCheckbox.bottomAnchor, constant: 18),
            sep.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            sep.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            // 속도 타이틀
            speedTitle.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 14),
            speedTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            // Duration row
            durationTitleLabel.topAnchor.constraint(equalTo: speedTitle.bottomAnchor, constant: 12),
            durationTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            durationTitleLabel.widthAnchor.constraint(equalToConstant: labelW),
            durationSlider.centerYAnchor.constraint(equalTo: durationTitleLabel.centerYAnchor),
            durationSlider.leadingAnchor.constraint(equalTo: durationTitleLabel.trailingAnchor, constant: 12),
            durationSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            durationLabel.centerYAnchor.constraint(equalTo: durationTitleLabel.centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            durationLabel.widthAnchor.constraint(equalToConstant: labelValW),

            // Steps row
            stepsTitleLabel.topAnchor.constraint(equalTo: durationTitleLabel.bottomAnchor, constant: 16),
            stepsTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            stepsTitleLabel.widthAnchor.constraint(equalToConstant: labelW),
            stepsSlider.centerYAnchor.constraint(equalTo: stepsTitleLabel.centerYAnchor),
            stepsSlider.leadingAnchor.constraint(equalTo: stepsTitleLabel.trailingAnchor, constant: 12),
            stepsSlider.trailingAnchor.constraint(equalTo: stepsLabel.leadingAnchor, constant: -8),
            stepsLabel.centerYAnchor.constraint(equalTo: stepsTitleLabel.centerYAnchor),
            stepsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            stepsLabel.widthAnchor.constraint(equalToConstant: labelValW),
        ])

        updateControlsEnabled()
    }

    private func updateControlsEnabled() {
        let on = Settings.shared.animationEnabled
        durationSlider.isEnabled = on
        stepsSlider.isEnabled = on
    }

    @objc private func enabledToggled() {
        Settings.shared.animationEnabled = (enabledCheckbox.state == .on)
        updateControlsEnabled()
    }

    @objc private func durationChanged() {
        let val = durationSlider.doubleValue
        Settings.shared.animationDuration = val
        durationLabel.stringValue = "\(String(format: "%.2f", val))초"
    }

    @objc private func stepsChanged() {
        let val = Int(stepsSlider.doubleValue)
        Settings.shared.animationSteps = val
        stepsLabel.stringValue = "\(val) 단계"
    }

    private func makeLabel(_ text: String, size: CGFloat, bold: Bool = false) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        return l
    }
}
