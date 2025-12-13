//
//  magicprinterApp.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import SwiftData

@main
struct magicprinter: App {
    // 1. Initialize Services (Idle state)
    // These objects exist, but their heavy initialization logic (scanning/recording)
    // is NOT running yet.
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var printerService = PrinterService()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([User.self, Sticker.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch { fatalError("Could not create ModelContainer: \(error)") }
    }()

    // We track the logged-in user here
    @State private var currentUser: User?

    var body: some Scene {
        WindowGroup {
            Group {
                if let user = currentUser {
                    // A. THE MAIN APP
                    // We only reach here after the wizard is complete.
                    MainView(
                        user: user,
                        onSwitchUser: { selectedUser in
                            handleUserSwitch(selectedUser)
                        },
                        speechRecognizer: speechRecognizer,
                        printerService: printerService
                    )
                    .transition(.opacity)
                    .onAppear {
                        // RE-START services when returning to main view
                        // (e.g. if we switched users)
                        print("Main View Active: Resuming services.")
                        speechRecognizer.prepare()
                        printerService.startScanning()
                    }
                } else {
                    // B. THE WIZARD FLOW
                    // We pass the idle services down. The Wizard will start them one by one.
                    OnboardingContainerView(
                        speechRecognizer: speechRecognizer,
                        printerService: printerService,
                        onComplete: { newUser in
                            // Wizard finished! Switch to Main View.
                            withAnimation {
                                currentUser = newUser
                            }
                        }
                    )
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    func handleUserSwitch(_ selectedUser: User) {
        if selectedUser.name.isEmpty {
            // Logic for "Add New User" -> Go back to onboarding
            // Note: In a polished app, you might want a simpler flow for 2nd users,
            // but going back to onboarding ensures permissions are re-checked safely.
            currentUser = nil
        } else {
            currentUser = selectedUser
        }
    }
}
