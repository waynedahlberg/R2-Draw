//
//  OnboardingButton.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/13/25.
//

import SwiftUI

struct OnboardingButton : View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    
    // Customization
    var color: Color = .blue
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 5)
                }
                
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                        .bold()
                }
                
                Text(title)
                    .bold()
            }
            .font(.title3)
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: color.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isLoading)
        .padding(.horizontal, 40)
    }
}

#Preview {
    VStack {
            OnboardingButton(title: "Get Started", icon: "arrow.right", action: {})
            OnboardingButton(title: "Connecting...", icon: nil, action: {}, isLoading: true)
        }
}
