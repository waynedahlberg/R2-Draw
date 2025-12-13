//
//  SpeechPermissionStepView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/13/25.
//

import SwiftUI

struct SpeechPermissionStepView: View {
    var speechRecognizer: SpeechRecognizer
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "mic.fill")
                .font(.system(size: 70))
                .foregroundStyle(.orange)
                .padding()
                .background(Circle().fill(.orange.opacity(0.1)).frame(width: 140, height: 140))
            
            Text("Enable Voice")
                .font(.title)
                .bold()
            
            Text("Magic Printer uses your voice to create prompts. We need access to the microphone to hear your ideas.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            OnboardingButton(
                title: "Allow Microphone",
                icon: "mic.badge.plus",
                action: requestMicrophone,
                color: .orange
            )
            
            Button("Maybe Later") {
                onNext()
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 50)
        }
    }
    
    func requestMicrophone() {
        // Trigger the OS Prompt
        speechRecognizer.requestAuthorization()
        // We move to the next screen regardless of the answer (Allowed or Denied)
        // In a polished app, you might wait for the callback.
        onNext()
    }
}
