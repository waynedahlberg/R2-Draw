//
//  WelcomeStepView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/13/25.
//

import SwiftUI

struct WelcomeStepView : View {
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
                .symbolEffect(.bounce, value: true)
            
            Text("Welcome to")
                .font(.caption)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("The Magic Printer")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Make coloring book stickers with your voice!")
            
            Spacer()
            
            OnboardingButton(title: "Get Started", icon: "arrow.right", action: onNext)
                .padding(.bottom, 128)
            
        }
    }
}

