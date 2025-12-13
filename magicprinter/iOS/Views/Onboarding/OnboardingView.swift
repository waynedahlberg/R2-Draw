//
//  OnboardingView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    // Actions
    var onSelectUser: (User) -> Void
    
    // Data
    @Query(sort: \User.createdAt, order: .reverse) private var users: [User]
    
    // Local State
    @State private var showCreateProfile = false
    
    // visual grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "pencil.and.scribble")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                            .padding(.top, 40)
                        
                        Text("Who is drawing?")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Tap your picture to start")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    // User Grid
                    LazyVGrid(columns: columns, spacing: 30) {
                        // 1. Existing Users
                        ForEach(users) { user in
                            Button {
                                onSelectUser(user)
                            } label: {
                                VStack(spacing: 12) {
                                    // This view is now ASYNC and won't block scrolling
                                    UserAvatarView(
                                        imageData: user.profileImageData,
                                        name: user.name,
                                        size: 100
                                    )
                                    .shadow(radius: 5)
                                    
                                    Text(user.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(20)
                            }
                        }
                        
                        // 2. "Add New" Button
                        Button {
                            showCreateProfile = true
                        } label: {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.largeTitle)
                                            .foregroundStyle(.primary)
                                    )
                                
                                Text("New Dreamer")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            .padding()
                            // Dashed border for "New" look
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                    .foregroundStyle(Color.secondary.opacity(0.5))
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("") // Hidden title for cleaner look
            .sheet(isPresented: $showCreateProfile) {
                CreateProfileView()
            }
        }
    }
}
