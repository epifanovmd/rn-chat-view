import UIKit

final class VoiceContentView: UIView {
    var onPlayTap: (() -> Void)?

    private let playButton = UIButton(type: .system)
    private let waveformView = WaveformView()
    private let durationLabel = UILabel()
    private var voiceURL: String?
    private var voiceDuration: TimeInterval = 0
    private var currentTheme: ChatTheme = .light
    private var isMineMessage = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        VoicePlayer.shared.removeObserver(self)
    }

    private func setup() {
        let L = ChatLayout.current
        let config = UIImage.SymbolConfiguration(pointSize: L.voicePlayIconSize, weight: .medium)
        playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        addSubview(playButton)

        waveformView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveformView)

        durationLabel.font = L.voiceDurationFont
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(durationLabel)

        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: L.voicePlaySize),
            playButton.heightAnchor.constraint(equalToConstant: L.voicePlaySize),
            waveformView.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            waveformView.trailingAnchor.constraint(equalTo: trailingAnchor),
            waveformView.topAnchor.constraint(equalTo: topAnchor),
            waveformView.heightAnchor.constraint(equalToConstant: L.voiceWaveformHeight),
            durationLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            durationLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 4),
            durationLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(voice: VoicePayload, isMine: Bool, theme: ChatTheme) {
        voiceURL = voice.url
        voiceDuration = voice.duration
        currentTheme = theme
        isMineMessage = isMine

        durationLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
        playButton.tintColor = isMine ? theme.outgoingText : theme.inputBarTint

        waveformView.configure(
            waveform: voice.waveform,
            activeColor: theme.voiceWaveformActive,
            inactiveColor: theme.voiceWaveformInactive,
            progress: 0
        )

        VoicePlayer.shared.addObserver(self)
        updateUI()
    }

    // MARK: - Обновление UI

    private func updateUI() {
        let state = VoicePlayer.shared.state
        let isMe = state.url == voiceURL
        let L = ChatLayout.current
        let config = UIImage.SymbolConfiguration(pointSize: L.voicePlayIconSize, weight: .medium)

        if isMe && state.isPlaying {
            playButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
        } else {
            playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        }

        if isMe, case .playing(_, let progress, let currentTime) = state {
            waveformView.updateProgress(progress)
            durationLabel.text = formatTime(currentTime)
        } else if isMe, case .paused(_, let progress, let currentTime) = state {
            waveformView.updateProgress(progress)
            durationLabel.text = formatTime(currentTime)
        } else {
            waveformView.updateProgress(0)
            durationLabel.text = formatTime(voiceDuration)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    @objc private func playTapped() { onPlayTap?() }
}

// MARK: - VoicePlayerObserver

extension VoiceContentView: VoicePlayerObserver {
    func voicePlayerDidChangeState(_ state: VoicePlayerState) {
        updateUI()
    }
}

// MARK: - WaveformView

final class WaveformView: UIView {
    private var bars: [CALayer] = []
    private var waveform: [Float] = []
    private var activeColor: UIColor = .systemBlue
    private var inactiveColor: UIColor = .lightGray
    private var progress: Float = 0

    func configure(waveform: [Float], activeColor: UIColor, inactiveColor: UIColor, progress: Float) {
        self.waveform = waveform.isEmpty ? Array(repeating: 0.3, count: 40) : waveform
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.progress = progress
        setNeedsLayout()
    }

    func updateProgress(_ progress: Float) {
        self.progress = progress
        updateBarColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bars.forEach { $0.removeFromSuperlayer() }
        bars.removeAll()

        guard bounds.width > 0 else { return }

        let barW = ChatLayout.current.voiceBarWidth
        let spacing = ChatLayout.current.voiceBarSpacing
        let totalW = barW + spacing
        let count = Int(bounds.width / totalW)
        guard count > 0 else { return }

        let normalized = resample(waveform, to: count)

        for i in 0..<count {
            let bar = CALayer()
            let h = max(2, CGFloat(normalized[i]) * bounds.height)
            bar.frame = CGRect(
                x: CGFloat(i) * totalW,
                y: (bounds.height - h) / 2,
                width: barW,
                height: h
            )
            bar.cornerRadius = barW / 2
            layer.addSublayer(bar)
            bars.append(bar)
        }
        updateBarColors()
    }

    private func updateBarColors() {
        let activeCount = Int(Float(bars.count) * progress)
        for (i, bar) in bars.enumerated() {
            bar.backgroundColor = (i < activeCount ? activeColor : inactiveColor).cgColor
        }
    }

    private func resample(_ data: [Float], to count: Int) -> [Float] {
        guard !data.isEmpty else { return Array(repeating: 0.3, count: count) }
        return (0..<count).map { i in
            let idx = Float(i) / Float(count) * Float(data.count)
            let lower = Int(idx)
            let upper = min(lower + 1, data.count - 1)
            let frac = idx - Float(lower)
            return data[lower] * (1 - frac) + data[upper] * frac
        }
    }
}
