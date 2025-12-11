//
//  OnboardingView.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \User.createdAt) private var users: [User]
    
    @State private var showingCreateProfile = false
    @State private var userToDelete: User?
    @State private var showDeleteConfirmation = false
    
    // We will bind this to the main app navigation later to "enter" the app
    // For now, it just prints who was selected.
    var onSelectUser: (User) -> Void
    
    var body: some View {
        VStack {
            if users.isEmpty {
                // Empty State: Welcome Screen
                ContentUnavailableView(
                    "Welcome to R2 Draw",
                    systemImage: "pencil.and.scribble",
                    description: Text("Let's get set up to start dreaming.")
                )
                
                Button("Add First Dreamer") {
                    showingCreateProfile = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top)
                
            } else {
                // User Grid
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Who is drawing?")
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 40)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 30) {
                            
                            // Existing Users
                            ForEach(users) { user in
                                Button {
                                    onSelectUser(user)
                                } label: {
                                    VStack {
                                        UserAvatarView(imageData: user.profileImageData, name: user.name, size: 100)
                                        Text(user.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                }
                                .contextMenu {
                                    Button("Delete Profile", systemImage: "trash", role: .destructive) {
                                        userToDelete = user
                                        showDeleteConfirmation = true
                                    }
                                }
                            }
                            
                            // Add New User Button
                            Button {
                                showingCreateProfile = true
                            } label: {
                                VStack {
                                    Circle()
                                        .fill(Color(.tertiarySystemFill))
                                        .frame(width: 100, height: 100)
                                        .overlay(Image(systemName: "plus").font(.largeTitle))
                                    
                                    Text("Add New")
                                        .font(.headline)
                                }
                                .padding()
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateProfile) {
            CreateProfileView()
        }
        // Double Confirmation Alert
        .alert("Delete \(userToDelete?.name ?? "Profile")?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let user = userToDelete {
                    modelContext.delete(user)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all stickers created by this dreamer. This cannot be undone.")
        }
    }
}
