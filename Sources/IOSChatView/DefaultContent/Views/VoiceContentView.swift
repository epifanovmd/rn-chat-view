import UIKit

public final class VoiceContentView: UIView {
    var onPlayTap: (() -> Void)?

    // MARK: - Вью

    private let playButton = UIView()
    private let playIcon = UIImageView()
    private let loadingRing = CAShapeLayer()
    private let waveformView = WaveformView()
    private let durationLabel = UILabel()

    // MARK: - Состояние

    private var voiceURL: String?
    private var voiceDuration: TimeInterval = 0
    private var currentTheme: ChatTheme = .light
    private var isOutgoingMessage = false
    private var accentColor: UIColor = .systemBlue
    private var isCached = false
    private var isPrefetching = false
    private var isFailed = false
    private var currentLayout = ChatLayout()

    // MARK: - Сохранённые констрейнты

    private var playButtonWidthConstraint: NSLayoutConstraint!
    private var playButtonHeightConstraint: NSLayoutConstraint!
    private var viewHeightConstraint: NSLayoutConstraint!
    private var waveformHeightConstraint: NSLayoutConstraint!
    private var waveformLeadingConstraint: NSLayoutConstraint!
    private var waveformTrailingConstraint: NSLayoutConstraint!

    // MARK: - Инициализация

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) { fatalError() }

    deinit {
        VoicePlayer.shared.removeObserver(self)
    }

    // MARK: - Настройка

    private func setup() {
        let L = currentLayout
        let btnSize = L.voicePlaySize

        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.layer.cornerRadius = btnSize / 2
        playButton.layer.masksToBounds = true
        playButton.isUserInteractionEnabled = true
        addSubview(playButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(playTapped))
        playButton.addGestureRecognizer(tap)

        playIcon.translatesAutoresizingMaskIntoConstraints = false
        playIcon.contentMode = .scaleAspectFit
        playIcon.tintColor = .white
        playButton.addSubview(playIcon)

        // Кольцо загрузки внутри кнопки
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

        waveformView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveformView)

        waveformView.onSeek = { [weak self] progress in
            guard let self, let url = self.voiceURL else { return }
            if VoicePlayer.shared.state.url == url {
                VoicePlayer.shared.seek(to: progress)
            }
        }

        durationLabel.font = L.voiceDurationFont
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(durationLabel)

        let config = UIImage.SymbolConfiguration(pointSize: L.voicePlayIconSize, weight: .semibold)
        playIcon.image = UIImage(systemName: "play.fill", withConfiguration: config)

        let waveH = btnSize - L.voiceDurationFont.lineHeight - 2

        let vPadTop: CGFloat = 8
        let vPadBottom: CGFloat = 4
        playButtonWidthConstraint = playButton.widthAnchor.constraint(equalToConstant: btnSize)
        playButtonHeightConstraint = playButton.heightAnchor.constraint(equalToConstant: btnSize)
        viewHeightConstraint = heightAnchor.constraint(equalToConstant: btnSize + vPadTop + vPadBottom)
        waveformHeightConstraint = waveformView.heightAnchor.constraint(equalToConstant: waveH)
        waveformLeadingConstraint = waveformView.leadingAnchor.constraint(
            equalTo: playButton.trailingAnchor, constant: L.voiceContentSpacing)
        waveformTrailingConstraint = waveformView.trailingAnchor.constraint(
            equalTo: trailingAnchor, constant: -L.voiceWaveformTrailingInset)

        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            playButton.topAnchor.constraint(equalTo: topAnchor, constant: vPadTop),
            playButtonWidthConstraint,
            playButtonHeightConstraint,
            viewHeightConstraint,

            playIcon.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),

            waveformLeadingConstraint,
            waveformTrailingConstraint,
            waveformView.topAnchor.constraint(equalTo: topAnchor, constant: vPadTop),
            waveformHeightConstraint,

            durationLabel.leadingAnchor.constraint(equalTo: waveformView.leadingAnchor),
            durationLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 2),
        ])
    }

    // MARK: - Конфигурация

    func configure(voice: VoicePayload, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout = ChatLayout()) {
        currentLayout = layout
        let L = currentLayout
        let btnSize = L.voicePlaySize

        voiceURL = voice.url
        voiceDuration = voice.duration
        let isOutgoing = ownership == .mine
        currentTheme = theme
        isOutgoingMessage = isOutgoing

        playButton.layer.cornerRadius = btnSize / 2
        durationLabel.font = L.voiceDurationFont

        let waveH = btnSize - L.voiceDurationFont.lineHeight - 2
        playButtonWidthConstraint.constant = btnSize
        playButtonHeightConstraint.constant = btnSize
        viewHeightConstraint.constant = btnSize + 12 // 8pt top + 4pt bottom padding
        waveformHeightConstraint.constant = waveH
        waveformLeadingConstraint.constant = L.voiceContentSpacing
        waveformTrailingConstraint.constant = -L.voiceWaveformTrailingInset

        // Пересоздание кольца загрузки под новый размер
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

        accentColor = isOutgoing ? theme.outgoingStatusRead : theme.voiceWaveformActive
        playButton.backgroundColor = accentColor
        playIcon.tintColor = .white
        loadingRing.strokeColor = UIColor.white.cgColor

        durationLabel.textColor = isOutgoing ? theme.outgoingTime : theme.incomingTime

        waveformView.configure(
            waveform: voice.waveform,
            activeColor: accentColor,
            inactiveColor: theme.voiceWaveformInactive,
            progress: 0,
            layout: L
        )

        isCached = AudioCache.shared.localURL(for: voice.url) != nil
        isFailed = false
        if !isCached {
            startPrefetch()
        }

        VoicePlayer.shared.addObserver(self)
        updateUI()
    }

    // MARK: - Обновление UI

    private func updateUI() {
        let state = VoicePlayer.shared.state
        let isMe = state.url == voiceURL
        let L = currentLayout
        let config = UIImage.SymbolConfiguration(pointSize: L.voicePlayIconSize, weight: .semibold)
        let errorConfig = UIImage.SymbolConfiguration(pointSize: L.voicePlayIconSize - 2, weight: .medium)

        if isFailed {
            hideLoadingRing()
            playButton.backgroundColor = accentColor.withAlphaComponent(0.4)
            playIcon.image = UIImage(systemName: "arrow.clockwise", withConfiguration: errorConfig)
            playIcon.alpha = 1
            waveformView.setDimmed(true)
            return
        }

        playButton.backgroundColor = accentColor
        waveformView.setDimmed(false)

        let isLoading = isPrefetching || (isMe && state.isLoading)

        if isLoading {
            playIcon.alpha = 0.3
            showLoadingRing()
        } else {
            playIcon.alpha = 1
            hideLoadingRing()
        }

        if isMe && state.isPlaying {
            playIcon.image = UIImage(systemName: "pause.fill", withConfiguration: config)
        } else {
            playIcon.image = UIImage(systemName: "play.fill", withConfiguration: config)
        }

        // Seek доступен только когда это голосовое играет или на паузе
        let isActive = isMe && (state.isPlaying || { if case .paused = state { return true }; return false }())
        waveformView.isSeekEnabled = isActive

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

    // MARK: - Кольцо загрузки

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

    // MARK: - Предзагрузка

    private func startPrefetch() {
        guard let url = voiceURL else { return }
        isPrefetching = true
        isFailed = false
        AudioCache.shared.fetch(url: url) { [weak self] localURL in
            guard let self, self.voiceURL == url else { return }
            self.isPrefetching = false
            if localURL != nil {
                self.isCached = true
                self.isFailed = false
            } else {
                self.isFailed = true
            }
            self.updateUI()
        }
    }

    // MARK: - Вспомогательные методы

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    @objc private func playTapped() {
        if isFailed {
            startPrefetch()
            updateUI()
            return
        }
        guard let url = voiceURL else { return }
        VoicePlayer.shared.toggle(url: url)
        onPlayTap?()
    }
}

// MARK: - VoicePlayerObserver

extension VoiceContentView: VoicePlayerObserver {
    public func voicePlayerDidChangeState(_ state: VoicePlayerState) {
        updateUI()
    }
}

// MARK: - WaveformView

public final class WaveformView: UIView, UIGestureRecognizerDelegate {
    var onSeek: ((Float) -> Void)?
    var isSeekEnabled = false

    private var bars: [CALayer] = []
    private var waveform: [Float] = []
    private var activeColor: UIColor = .systemBlue
    private var inactiveColor: UIColor = .lightGray
    private var progress: Float = 0
    private var isSeeking = false
    private var didLockDirection = false
    private var isHorizontalPan = false
    private var isDimmed = false
    private var currentLayout = ChatLayout()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    public required init?(coder: NSCoder) { fatalError() }

    func configure(waveform: [Float], activeColor: UIColor, inactiveColor: UIColor, progress: Float, layout: ChatLayout = ChatLayout()) {
        self.waveform = waveform.isEmpty
            ? Array(repeating: 0.3, count: 40)
            : Self.normalize(waveform)
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.progress = progress
        self.currentLayout = layout
        setNeedsLayout()
    }

    func updateProgress(_ progress: Float) {
        guard !isSeeking else { return }
        self.progress = progress
        updateBarColors()
    }

    func setDimmed(_ dimmed: Bool) {
        isDimmed = dimmed
        updateBarColors()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        rebuildBars()
    }

    private func rebuildBars() {
        bars.forEach { $0.removeFromSuperlayer() }
        bars.removeAll()

        guard bounds.width > 0, bounds.height > 0 else { return }

        let barW = currentLayout.voiceBarWidth
        let spacing = currentLayout.voiceBarSpacing
        let totalW = barW + spacing
        let count = Int(bounds.width / totalW)
        guard count > 0 else { return }

        let normalized = resample(waveform, to: count)
        let minH = currentLayout.voiceBarMinHeight

        for i in 0..<count {
            let bar = CALayer()
            let level = min(max(CGFloat(normalized[i]), 0), 1)
            let h = max(minH, level * bounds.height)
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
        if isDimmed {
            let dimColor = inactiveColor.withAlphaComponent(0.3).cgColor
            bars.forEach { $0.backgroundColor = dimColor }
            return
        }
        let activeCount = Int(Float(bars.count) * progress)
        for (i, bar) in bars.enumerated() {
            bar.backgroundColor = (i < activeCount ? activeColor : inactiveColor).cgColor
        }
    }

    // MARK: - Жесты перемотки

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isSeekEnabled else {
            gesture.state = .cancelled
            return
        }

        switch gesture.state {
        case .began:
            didLockDirection = false
            isHorizontalPan = false
        case .changed:
            if !didLockDirection {
                let velocity = gesture.velocity(in: self)
                if abs(velocity.x) < abs(velocity.y) {
                    // Вертикальный жест — отменяем, чтобы scroll view обработал
                    gesture.state = .cancelled
                    return
                }
                didLockDirection = true
                isHorizontalPan = true
                isSeeking = true
            }

            if isHorizontalPan {
                let x = gesture.location(in: self).x
                let clamped = max(0, min(1, Float(x / bounds.width)))
                progress = clamped
                updateBarColors()
            }
        case .ended, .cancelled:
            if isSeeking {
                let x = gesture.location(in: self).x
                let clamped = max(0, min(1, Float(x / bounds.width)))
                isSeeking = false
                progress = clamped
                updateBarColors()
                onSeek?(clamped)
            }
            didLockDirection = false
            isHorizontalPan = false
        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard isSeekEnabled else { return }
        let x = gesture.location(in: self).x
        let clamped = max(0, min(1, Float(x / bounds.width)))
        progress = clamped
        updateBarColors()
        onSeek?(clamped)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    // MARK: - Нормализация

    /// Приводит амплитуды к 0…1 по максимуму: источник (рекордер, сервер)
    /// может отдавать произвольную шкалу, иначе столбики вылезают за область
    /// волны и обрезаются краем пузыря.
    static func normalize(_ data: [Float]) -> [Float] {
        guard let peak = data.map({ abs($0) }).max(), peak > 0 else {
            return Array(repeating: 0, count: data.count)
        }
        return data.map { min(abs($0) / peak, 1) }
    }

    // MARK: - Ресемплинг

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
