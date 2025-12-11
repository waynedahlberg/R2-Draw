//
//  r2drawApp.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import SwiftData

@main
struct StickerDreamApp: App {
    // MARK: - SwiftData Container
    // We initialize the container for both User and Sticker models.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([User.self, Sticker.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var currentUser: User?

    var body: some Scene {
        WindowGroup {
            if let user = currentUser {
                // MARK: - Main app interface
                // Temporary: way to log out and test the flow
                VStack {
                    Text("Hello, \(user.name)!")
                        .font(.largeTitle)
                    
                    Button("Switch User") {
                        currentUser = nil
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // MARK: - Onboarding
                OnboardingView { selectedUser in
                    withAnimation {
                        currentUser = selectedUser
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
