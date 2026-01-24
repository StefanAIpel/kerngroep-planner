//
//  AudioService.swift
//  Werkgeheugen
//
//  Audio recording for voice capture
//

import Foundation
import AVFoundation

class AudioService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?

    private let audioSession = AVAudioSession.sharedInstance()

    // MARK: - Recording

    func startRecording() -> URL? {
        errorMessage = nil

        // Configure audio session
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            errorMessage = "Kon audio sessie niet configureren: \(error.localizedDescription)"
            return nil
        }

        // Check permission
        guard audioSession.recordPermission == .granted else {
            requestPermission()
            return nil
        }

        // Create unique filename
        let filename = "voice_\(Date().timeIntervalSince1970).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(filename)

        // Recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            isRecording = true
            recordingDuration = 0

            // Start duration timer
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0
            }

            // Start level meter
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.audioRecorder?.updateMeters()
                let level = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
                // Convert dB to 0-1 range
                self?.audioLevel = max(0, (level + 60) / 60)
            }

            HapticFeedback.medium()
            return audioURL

        } catch {
            errorMessage = "Kon opname niet starten: \(error.localizedDescription)"
            return nil
        }
    }

    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else { return nil }

        let url = recorder.url

        recorder.stop()
        audioRecorder = nil
        isRecording = false

        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil

        HapticFeedback.light()

        return url
    }

    func cancelRecording() {
        guard isRecording, let recorder = audioRecorder else { return }

        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        isRecording = false

        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil

        // Delete the file
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Playback

    func playAudio(at url: URL) {
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            errorMessage = "Kon audio niet afspelen: \(error.localizedDescription)"
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    // MARK: - Permission

    func requestPermission() {
        audioSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.errorMessage = "Geef toestemming voor microfoon in Instellingen"
                }
            }
        }
    }

    var hasPermission: Bool {
        audioSession.recordPermission == .granted
    }

    // MARK: - File Management

    func deleteAudioFile(at path: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
    }

    func audioFileExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Formatting

    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Opname is niet gelukt"
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        errorMessage = error?.localizedDescription ?? "Encoding fout"
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer = nil
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        errorMessage = error?.localizedDescription ?? "Playback fout"
    }
}
