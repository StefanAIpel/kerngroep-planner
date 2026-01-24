//
//  SpeechService.swift
//  Werkgeheugen
//
//  Speech-to-text transcription using iOS Speech framework
//

import Foundation
import Speech
import AVFoundation

class SpeechService: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    @Published var isAvailable = false

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        // Initialize with Dutch locale
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "nl-NL"))
        checkAvailability()
    }

    // MARK: - Availability

    private func checkAvailability() {
        isAvailable = speechRecognizer?.isAvailable ?? false
    }

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.checkAvailability()
                    completion(true)
                case .denied:
                    self?.errorMessage = "Spraakherkenning geweigerd. Ga naar Instellingen om toestemming te geven."
                    completion(false)
                case .restricted:
                    self?.errorMessage = "Spraakherkenning is beperkt op dit apparaat."
                    completion(false)
                case .notDetermined:
                    self?.errorMessage = "Spraakherkenning status onbekend."
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    var hasPermission: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: - Transcribe Audio File

    func transcribeAudioFile(at url: URL, completion: @escaping (String?) -> Void) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Spraakherkenning niet beschikbaar"
            completion(nil)
            return
        }

        isTranscribing = true
        transcribedText = ""
        errorMessage = nil

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        // Use on-device recognition if available (iOS 13+)
        if #available(iOS 13.0, *) {
            request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isTranscribing = false

                if let error = error {
                    self?.errorMessage = "Transcriptie fout: \(error.localizedDescription)"
                    completion(nil)
                    return
                }

                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self?.transcribedText = text
                    completion(text)
                } else {
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Live Transcription (for real-time recording)

    func startLiveTranscription() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Spraakherkenning niet beschikbaar"
            return
        }

        // Cancel any ongoing task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio sessie fout: \(error.localizedDescription)"
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Kon herkenningsverzoek niet maken"
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        // Use on-device if available
        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isTranscribing = true
            transcribedText = ""
        } catch {
            errorMessage = "Audio engine kon niet starten: \(error.localizedDescription)"
            return
        }

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self?.stopLiveTranscription()
                }
            }
        }
    }

    func stopLiveTranscription() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }

    // MARK: - Cancel

    func cancelTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
        transcribedText = ""
    }
}

// MARK: - Language Support
extension SpeechService {
    static var supportedLocales: [Locale] {
        SFSpeechRecognizer.supportedLocales().sorted { $0.identifier < $1.identifier }
    }

    static var dutchAvailable: Bool {
        supportedLocales.contains { $0.identifier.starts(with: "nl") }
    }
}
