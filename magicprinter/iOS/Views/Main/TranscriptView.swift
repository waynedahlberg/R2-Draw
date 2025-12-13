//
//  TranscriptView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import SwiftUI

struct TranscriptView : View {
    let text: String
    let isRecording: Bool
    
    var body: some View {
        Text(text)
            .font(.title2)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .frame(height: 80)
            .padding(.horizontal)
            // if recording, animate changes smoothly
            .animation(.default, value: text)
    }
}
