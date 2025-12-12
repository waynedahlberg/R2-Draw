//
//  r2drawApp.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import SwiftData

@main
struct R2DrawApp: App {
    // MARK: - App-Level State (Singletons for this app instance)
    // These initialize ONCE and stay alive for the session.
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var printerService = PrinterService()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([User.self, Sticker.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch { fatalError("Could not create ModelContainer: \(error)") }
    }()

    @State private var currentUser: User?

    var body: some Scene {
        WindowGroup {
            Group {
                if let user = currentUser {
                    // Inject the pre-warmed services
                    MainView(
                        user: user,
                        onSwitchUser: { handleUserSwitch($0) },
                        speechRecognizer: speechRecognizer,
                        printerService: printerService
                    )
                    .transition(.opacity)
                } else {
                    OnboardingView { selectedUser in
                        withAnimation {
                            currentUser = selectedUser
                        }
                    }
                }
            }
            // MARK: - App Warmup
            .task {
                // Background warmup when app launches
                speechRecognizer.prepare()
                
                // Optional: Start bluetooth scanning immediately
                // printerService.startScanning()
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    func handleUserSwitch(_ selectedUser: User) {
        if selectedUser.name.isEmpty {
            // Signal to go back to Onboarding/Creation
            currentUser = nil
        } else {
            currentUser = selectedUser
        }
    }
}
