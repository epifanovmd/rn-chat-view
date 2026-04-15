import AVFoundation
import UIKit

// MARK: - Состояние плеера

public enum VoicePlayerState: Equatable {
    case idle
    case loading(url: String)
    case playing(url: String, progress: Float, currentTime: TimeInterval)
    case paused(url: String, progress: Float, currentTime: TimeInterval)

    var url: String? {
        switch self {
        case .idle: return nil
        case .loading(let u): return u
        case .playing(let u, _, _): return u
        case .paused(let u, _, _): return u
        }
    }

    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

// MARK: - Протокол наблюдателя

public protocol VoicePlayerObserver: AnyObject {
    func voicePlayerDidChangeState(_ state: VoicePlayerState)
}

// MARK: - AudioCache

public final class AudioCache {
    public static let shared = AudioCache()

    private let cacheDir: URL
    private let fileManager = FileManager.default
    private let lock = NSLock()
    private var inFlight: [String: [(URL?) -> Void]] = [:]

    private init() {
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VoiceCache", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        cacheDir = dir
    }

    func localURL(for remoteURL: String) -> URL? {
        let file = cacheDir.appendingPathComponent(remoteURL.sha256FileName)
        return fileManager.fileExists(atPath: file.path) ? file : nil
    }

    func fetch(url remoteURL: String, completion: @escaping (URL?) -> Void) {
        if let local = localURL(for: remoteURL) {
            completion(local)
            return
        }

        lock.lock()
        if inFlight[remoteURL] != nil {
            inFlight[remoteURL]?.append(completion)
            lock.unlock()
            return
        }
        inFlight[remoteURL] = [completion]
        lock.unlock()

        guard let url = URL(string: remoteURL) else {
            deliver(remoteURL: remoteURL, local: nil)
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self, let tempURL, error == nil else {
                self?.deliver(remoteURL: remoteURL, local: nil)
                return
            }
            let dest = self.cacheDir.appendingPathComponent(remoteURL.sha256FileName)
            try? self.fileManager.removeItem(at: dest)
            do {
                try self.fileManager.moveItem(at: tempURL, to: dest)
                self.deliver(remoteURL: remoteURL, local: dest)
            } catch {
                self.deliver(remoteURL: remoteURL, local: nil)
            }
        }
        task.resume()
    }

    private func deliver(remoteURL: String, local: URL?) {
        lock.lock()
        let handlers = inFlight.removeValue(forKey: remoteURL) ?? []
        lock.unlock()
        DispatchQueue.main.async {
            handlers.forEach { $0(local) }
        }
    }
}

private extension String {
    var sha256FileName: String {
        let data = Data(utf8)
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buf in
            _ = CC_SHA256(buf.baseAddress, CC_LONG(data.count), &hash)
        }
        let ext = (self as NSString).pathExtension
        let name = hash.map { String(format: "%02x", $0) }.joined()
        return ext.isEmpty ? name : "\(name).\(ext)"
    }
}

import CommonCrypto

// MARK: - VoicePlayer

public final class VoicePlayer {
    public static let shared = VoicePlayer()

    private(set) var state: VoicePlayerState = .idle {
        didSet { notifyObservers() }
    }

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?

    private struct WeakObserver {
        weak var value: VoicePlayerObserver?
    }
    private var observers: [WeakObserver] = []

    private init() {}

    // MARK: - Наблюдатели

    public func addObserver(_ observer: VoicePlayerObserver) {
        observers.removeAll { $0.value == nil }
        guard !observers.contains(where: { $0.value === observer }) else { return }
        observers.append(WeakObserver(value: observer))
    }

    public func removeObserver(_ observer: VoicePlayerObserver) {
        observers.removeAll { $0.value == nil || $0.value === observer }
    }

    private func notifyObservers() {
        observers.removeAll { $0.value == nil }
        for obs in observers { obs.value?.voicePlayerDidChangeState(state) }
    }

    // MARK: - Публичное API

    public func toggle(url: String) {
        switch state {
        case .playing(let u, _, _) where u == url:
            pause()
        case .paused(let u, let p, let t) where u == url:
            resume(url: u, progress: p, currentTime: t)
        default:
            play(url: url)
        }
    }

    public func stop() {
        cleanup()
        state = .idle
    }

    public func pauseIfPlaying() {
        guard case .playing = state else { return }
        pause()
    }

    public func seek(to progress: Float) {
        guard let player, let item = player.currentItem else { return }
        let duration = CMTimeGetSeconds(item.duration)
        guard duration > 0, duration.isFinite else { return }
        let target = CMTime(seconds: Double(progress) * duration, preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)

        switch state {
        case .playing(let u, _, _):
            state = .playing(url: u, progress: progress, currentTime: Double(progress) * duration)
        case .paused(let u, _, _):
            state = .paused(url: u, progress: progress, currentTime: Double(progress) * duration)
        default:
            break
        }
    }

    // MARK: - Приватные методы

    private func play(url: String) {
        cleanup()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            state = .idle
            return
        }

        // Сначала проверяем кэш — мгновенное воспроизведение если есть
        if let cachedURL = AudioCache.shared.localURL(for: url) {
            startPlayback(url: url, fileURL: cachedURL)
            return
        }

        // Нет в кэше — показываем загрузку, скачиваем
        state = .loading(url: url)

        AudioCache.shared.fetch(url: url) { [weak self] localURL in
            guard let self, case .loading(let u) = self.state, u == url else { return }

            let assetURL: URL
            if let localURL {
                assetURL = localURL
            } else if let remote = URL(string: url) {
                assetURL = remote
            } else {
                self.state = .idle
                return
            }

            self.startPlayback(url: url, fileURL: assetURL)
        }
    }

    private func startPlayback(url: String, fileURL: URL) {
        let item = AVPlayerItem(asset: AVURLAsset(url: fileURL))
        player = AVPlayer(playerItem: item)

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            if item.status == .readyToPlay {
                self.statusObservation = nil
                self.player?.play()
                self.state = .playing(url: url, progress: 0, currentTime: 0)
            } else if item.status == .failed {
                self.statusObservation = nil
                self.stop()
            }
        }

        setupObservers(url: url)
    }

    private func pause() {
        guard case .playing(let url, let progress, let currentTime) = state else { return }
        player?.pause()
        state = .paused(url: url, progress: progress, currentTime: currentTime)
    }

    private func resume(url: String, progress: Float, currentTime: TimeInterval) {
        player?.play()
        state = .playing(url: url, progress: progress, currentTime: currentTime)
    }

    private func setupObservers(url: String) {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, case .playing(let u, _, _) = self.state, u == url else { return }
            let current = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(self.player?.currentItem?.duration ?? .zero)
            guard duration > 0, duration.isFinite else { return }
            let progress = Float(current / duration)
            self.state = .playing(url: u, progress: progress, currentTime: current)
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem, queue: .main
        ) { [weak self] _ in
            self?.stop()
        }
    }

    private func cleanup() {
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        if let obs = endObserver { NotificationCenter.default.removeObserver(obs) }
        timeObserver = nil
        endObserver = nil
        statusObservation = nil
        player?.pause()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    deinit { cleanup() }
}
