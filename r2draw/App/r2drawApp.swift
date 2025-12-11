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
            if let user = currentUser {
                // MARK: - Pass the switcher logic here
                MainView(user: user) { selectedUser in
                    // If name is empty, it means "Add New" (hack from Step 1)
                    if selectedUser.name.isEmpty {
                        currentUser = nil // Go back to onboarding
                    } else {
                        currentUser = selectedUser // Switch user
                    }
                }
                .transition(.opacity)
            } else {
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
