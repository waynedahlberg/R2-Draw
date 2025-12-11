//
//  SpeechService.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import Foundation
import Speech
import AVFoundation

@Observable
final class SpeechRecognizer {
    enum RecognizerState {
        case idle
        case recording
        case processing
        case error(String)
    }
    
    var state: RecognizerState = .idle
    var transcript: String = ""
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            // Handle status if needed (e.g., show alert if denied)
        }
    }
    
    func startTranscribing() {
        guard !audioEngine.isRunning else { return }
        
        // Reset
        self.transcript = ""
        self.state = .recording
        
        // Setup Audio Session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.state = .error("Audio Session Error: \(error.localizedDescription)")
            return
        }
        
        // Setup Request
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        
        // Check input node
        let inputNode = audioEngine.inputNode
        
        // Start Task
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopTranscribing()
            }
        }
        
        // Install Tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request?.append(buffer)
        }
        
        // Start Engine
        do {
            try audioEngine.start()
        } catch {
            self.state = .error("Audio Engine Error: \(error.localizedDescription)")
        }
    }
    
    func stopTranscribing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        
        request = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.state = .idle
        }
    }
}
