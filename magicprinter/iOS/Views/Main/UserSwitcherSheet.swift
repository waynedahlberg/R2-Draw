//
//  UserSwitcherSheet.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import SwiftUI

struct UserSwitcherSheet: View {
    // DATA
    let users: [User]
    let currentUser: User
    
    // ACTION
    let onSwitch: (User) -> Void
    
    // ENVIRONMENT
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. Drag Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top)
            
            // 2. Title
            Text("Switch Dreamer")
                .font(.headline)
                .padding(.bottom, 10)
            
            // 3. User List
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Existing Users
                    ForEach(users) { otherUser in
                        Button {
                            // Close the sheet first, then switch
                            // We do this logic in MainView via the closure, but the UI feedback happens here
                            onSwitch(otherUser)
                        } label: {
                            HStack {
                                UserAvatarView(imageData: otherUser.profileImageData, name: otherUser.name, size: 50)
                                
                                Text(otherUser.name)
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                // Selected Indicator
                                if otherUser.id == currentUser.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            // Visual touch feedback for the whole row
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain) // Removes default button flash, keeps custom look
                    }
                    
                    // "Add New" Button
                    Button {
                        // Create a dummy user to signal "New" to the parent view
                        onSwitch(User(name: "", profileImageData: nil))
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 50, height: 50)
                                .overlay(Image(systemName: "plus").font(.title2))
                            
                            Text("Add New Dreamer")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 50) // Bottom padding for safe area
            }
        }
        .presentationDetents([.fraction(0.4), .medium]) // Half-height sheet
        .presentationDragIndicator(.visible)
    }
}
