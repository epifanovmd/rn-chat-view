import AVFoundation
import UIKit

// MARK: - Delegate

protocol VoiceRecorderDelegate: AnyObject {
    func voiceRecorderDidStart()
    func voiceRecorderDidStop(fileURL: URL, duration: TimeInterval, waveform: [Float])
    func voiceRecorderDidCancel()
    func voiceRecorderDidFail(error: Error)
    func voiceRecorderDidUpdateDuration(_ duration: TimeInterval)
    func voiceRecorderDidUpdateLevel(_ level: Float)
}

// MARK: - VoiceRecorder

final class VoiceRecorder: NSObject {
    weak var delegate: VoiceRecorderDelegate?

    private var recorder: AVAudioRecorder?
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var waveformSamples: [Float] = []
    private(set) var isRecording = false

    func startRecording() {
        requestPermission { [weak self] granted in
            DispatchQueue.main.async {
                granted ? self?.beginRecording() : self?.delegate?.voiceRecorderDidFail(
                    error: NSError(domain: "VoiceRecorder", code: 1,
                                   userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
                )
            }
        }
    }

    func stopRecording() {
        guard isRecording, let recorder else { return }
        let url = recorder.url
        let duration = recorder.currentTime
        let waveform = waveformSamples
        recorder.stop()
        isRecording = false
        waveformSamples.removeAll()
        stopDisplayLink()
        deactivateSession()
        delegate?.voiceRecorderDidStop(fileURL: url, duration: duration, waveform: waveform)
    }

    func cancelRecording() {
        guard isRecording, let recorder else { return }
        recorder.stop()
        recorder.deleteRecording()
        isRecording = false
        waveformSamples.removeAll()
        stopDisplayLink()
        deactivateSession()
        delegate?.voiceRecorderDidCancel()
    }



    // MARK: - Private

    private func requestPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17, *) {
            AVAudioApplication.requestRecordPermission { granted in completion(granted) }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in completion(granted) }
        }
    }

    private func beginRecording() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.delegate = self
            recorder?.record()

            isRecording = true
            waveformSamples.removeAll()
            startTime = CACurrentMediaTime()
            startDisplayLink()
            delegate?.voiceRecorderDidStart()
        } catch {
            delegate?.voiceRecorderDidFail(error: error)
        }
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: 30)
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        guard let recorder, isRecording else { return }
        recorder.updateMeters()
        let level = max(0, 1 + recorder.averagePower(forChannel: 0) / 50)
        waveformSamples.append(level)
        delegate?.voiceRecorderDidUpdateDuration(recorder.currentTime)
        delegate?.voiceRecorderDidUpdateLevel(level)
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceRecorder: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        isRecording = false
        stopDisplayLink()
        if let error { delegate?.voiceRecorderDidFail(error: error) }
    }
}
