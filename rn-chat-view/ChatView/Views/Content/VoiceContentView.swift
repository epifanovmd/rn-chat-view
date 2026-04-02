import UIKit

final class VoiceContentView: UIView {
    var onPlayTap: (() -> Void)?

    // MARK: - Subviews

    private let playButton = UIView()
    private let playIcon = UIImageView()
    private let loadingRing = CAShapeLayer()
    private let waveformView = WaveformView()
    private let durationLabel = UILabel()

    // MARK: - State

    private var voiceURL: String?
    private var voiceDuration: TimeInterval = 0
    private var currentTheme: ChatTheme = .light
    private var isMineMessage = false
    private var isCached = false
    private var isPrefetching = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        VoicePlayer.shared.removeObserver(self)
    }

    // MARK: - Setup

    private func setup() {
        let L = ChatLayout.current
        let btnSize = L.voicePlaySize

        // Play button
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.layer.cornerRadius = btnSize / 2
        playButton.layer.masksToBounds = true
        playButton.isUserInteractionEnabled = true
        addSubview(playButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(playTapped))
        playButton.addGestureRecognizer(tap)

        // Play icon
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        playIcon.contentMode = .scaleAspectFit
        playIcon.tintColor = .white
        playButton.addSubview(playIcon)

        // Loading ring inside button
        let inset: CGFloat = 4
        let ringRadius = btnSize / 2 - inset
        loadingRing.frame = CGRect(x: 0, y: 0, width: btnSize, height: btnSize)
        loadingRing.path = UIBezierPath(
            arcCenter: CGPoint(x: btnSize / 2, y: btnSize / 2),
            radius: ringRadius,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        ).cgPath
        loadingRing.fillColor = UIColor.clear.cgColor
        loadingRing.strokeColor = UIColor.white.cgColor
        loadingRing.lineWidth = 2
        loadingRing.lineCap = .round
        loadingRing.strokeStart = 0
        loadingRing.strokeEnd = 0.75
        loadingRing.isHidden = true
        playButton.layer.addSublayer(loadingRing)

        // Waveform
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveformView)

        waveformView.onSeek = { [weak self] progress in
            guard let self, let url = self.voiceURL else { return }
            if VoicePlayer.shared.state.url == url {
                VoicePlayer.shared.seek(to: progress)
            }
        }

        // Duration
        durationLabel.font = L.voiceDurationFont
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(durationLabel)

        let config = UIImage.SymbolConfiguration(pointSize: L.voicePlayIconSize, weight: .semibold)
        playIcon.image = UIImage(systemName: "play.fill", withConfiguration: config)

        let waveH = btnSize - L.voiceDurationFont.lineHeight - 2
        let contentLeading: CGFloat = 10

        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            playButton.topAnchor.constraint(equalTo: topAnchor),
            playButton.widthAnchor.constraint(equalToConstant: btnSize),
            playButton.heightAnchor.constraint(equalToConstant: btnSize),
            heightAnchor.constraint(equalToConstant: btnSize),

            playIcon.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),

            waveformView.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: contentLeading),
            waveformView.trailingAnchor.constraint(equalTo: trailingAnchor),
            waveformView.topAnchor.constraint(equalTo: topAnchor),
            waveformView.heightAnchor.constraint(equalToConstant: waveH),

            durationLabel.leadingAnchor.constraint(equalTo: waveformView.leadingAnchor),
            durationLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 2),
        ])
    }

    // MARK: - Configure

    func configure(voice: VoicePayload, isMine: Bool, theme: ChatTheme) {
        voiceURL = voice.url
        voiceDuration = voice.duration
        currentTheme = theme
        isMineMessage = isMine

        let accentColor = isMine ? theme.outgoingStatusRead : theme.voiceWaveformActive
        playButton.backgroundColor = accentColor
        playIcon.tintColor = .white
        loadingRing.strokeColor = UIColor.white.cgColor

        durationLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime

        waveformView.configure(
            waveform: voice.waveform,
            activeColor: accentColor,
            inactiveColor: theme.voiceWaveformInactive,
            progress: 0
        )

        // Check cache and prefetch
        isCached = AudioCache.shared.localURL(for: voice.url) != nil
        if !isCached {
            isPrefetching = true
            AudioCache.shared.fetch(url: voice.url) { [weak self] localURL in
                guard let self, self.voiceURL == voice.url else { return }
                self.isCached = localURL != nil
                self.isPrefetching = false
                self.updateUI()
            }
        }

        VoicePlayer.shared.addObserver(self)
        updateUI()
    }

    // MARK: - Update UI

    private func updateUI() {
        let state = VoicePlayer.shared.state
        let isMe = state.url == voiceURL
        let L = ChatLayout.current
        let config = UIImage.SymbolConfiguration(pointSize: L.voicePlayIconSize, weight: .semibold)

        // Loading: prefetching or player loading
        let isLoading = isPrefetching || (isMe && state.isLoading)

        if isLoading {
            playIcon.alpha = 0.3
            showLoadingRing()
        } else {
            playIcon.alpha = 1
            hideLoadingRing()
        }

        // Play / Pause icon
        if isMe && state.isPlaying {
            playIcon.image = UIImage(systemName: "pause.fill", withConfiguration: config)
        } else {
            playIcon.image = UIImage(systemName: "play.fill", withConfiguration: config)
        }

        // Waveform + duration
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

    // MARK: - Loading Ring

    private func showLoadingRing() {
        guard loadingRing.isHidden else { return }
        loadingRing.isHidden = false
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 0.8
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        loadingRing.add(rotation, forKey: "spin")
    }

    private func hideLoadingRing() {
        guard !loadingRing.isHidden else { return }
        loadingRing.removeAnimation(forKey: "spin")
        loadingRing.isHidden = true
    }

    // MARK: - Helpers

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
    var onSeek: ((Float) -> Void)?

    private var bars: [CALayer] = []
    private var waveform: [Float] = []
    private var activeColor: UIColor = .systemBlue
    private var inactiveColor: UIColor = .lightGray
    private var progress: Float = 0
    private var isSeeking = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(waveform: [Float], activeColor: UIColor, inactiveColor: UIColor, progress: Float) {
        self.waveform = waveform.isEmpty ? Array(repeating: 0.3, count: 40) : waveform
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.progress = progress
        setNeedsLayout()
    }

    func updateProgress(_ progress: Float) {
        guard !isSeeking else { return }
        self.progress = progress
        updateBarColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rebuildBars()
    }

    private func rebuildBars() {
        bars.forEach { $0.removeFromSuperlayer() }
        bars.removeAll()

        guard bounds.width > 0, bounds.height > 0 else { return }

        let barW = ChatLayout.current.voiceBarWidth
        let spacing = ChatLayout.current.voiceBarSpacing
        let totalW = barW + spacing
        let count = Int(bounds.width / totalW)
        guard count > 0 else { return }

        let normalized = resample(waveform, to: count)
        let minH: CGFloat = 2

        for i in 0..<count {
            let bar = CALayer()
            let h = max(minH, CGFloat(normalized[i]) * bounds.height)
            bar.frame = CGRect(
                x: CGFloat(i) * totalW,
                y: bounds.height - h,
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

    // MARK: - Seek gestures

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let x = gesture.location(in: self).x
        let clamped = max(0, min(1, Float(x / bounds.width)))

        switch gesture.state {
        case .began:
            isSeeking = true
            progress = clamped
            updateBarColors()
        case .changed:
            progress = clamped
            updateBarColors()
        case .ended, .cancelled:
            isSeeking = false
            progress = clamped
            updateBarColors()
            onSeek?(clamped)
        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let x = gesture.location(in: self).x
        let clamped = max(0, min(1, Float(x / bounds.width)))
        progress = clamped
        updateBarColors()
        onSeek?(clamped)
    }

    // MARK: - Resample

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
