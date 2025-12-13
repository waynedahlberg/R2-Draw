//
//  OnboardingContainerView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/13/25.
//

import SwiftUI

enum OnboardingStep {
    case welcome
    case bluetoothPermission
    case printerScan
    case speechPermission
    case createProfile
}

struct OnboardingContainerView: View {
    // We receive the heavy services here, but pass them down
    // only when needed.
    var speechRecognizer: SpeechRecognizer
    var printerService: PrinterService
    
    // The "Brain" of the flow
    @State private var currentStep: OnboardingStep = .welcome
    
    // Final callback when everything is done
    var onComplete: (User) -> Void
    
    var body: some View {
        ZStack {
            // Background Layer (Consistent across all steps)
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // Step Switcher
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeStepView {
                        withAnimation { currentStep = .bluetoothPermission }
                    }
                    
                case .bluetoothPermission:
                    BluetoothPermissionStepView {
                        withAnimation { currentStep = .printerScan }
                    }
                    
                case .printerScan:
                    PrinterScannerStepView(printerService: printerService) {
                        withAnimation { currentStep = .speechPermission }
                    }
                    
                case .speechPermission:
                    SpeechPermissionStepView(speechRecognizer: speechRecognizer) {
                        withAnimation { currentStep = .createProfile }
                    }
                    
                case .createProfile:
                    // This uses your existing view, wrapped to handle the callback
                    CreateProfileStepView { user in
                        onComplete(user)
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }
}
