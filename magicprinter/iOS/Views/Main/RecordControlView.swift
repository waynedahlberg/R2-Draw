//
//  RecordControlView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import SwiftUI

struct RecordControlView : View {
    let isRecording: Bool
    let isReady: Bool
    let isGenerating: Bool
    
    // Actions
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // The Record button
            Button {
                // Action handled by DragGesture
            } label: {
                ZStack {
                    // Pulse effect
                    if isRecording {
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .scaleEffect(1.2)
                            .transition(.opacity)
                    }
                    
                    // Main Circle
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 4, y: 2)
                    
                    // Icon
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .opacity(isReady ? 1.0 : 0.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isRecording)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isRecording && !isGenerating && isReady {
                            onStartRecording()
                        }
                    }
                    .onEnded { _ in
                        if isRecording {
                            onStopRecording()
                        }
                    }
            )
            .disabled(isGenerating || !isReady)
            
            // Status Text
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // Logic for visuals
    private var buttonColor: Color {
        if isRecording { return .red }
        return isReady ? .blue : .gray
    }
    
    private var statusText: String {
        if isRecording { return "Listening..." }
        if !isReady { return "Warming up..." }
        return "Hold to speak"
    }
}
