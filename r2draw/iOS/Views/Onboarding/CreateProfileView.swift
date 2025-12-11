//
//  CreateProfileView.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import PhotosUI
import SwiftData

struct CreateProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                
                // Header
                Text("Who is this dreamer?")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // Photo Picker
                VStack {
                    UserAvatarView(imageData: selectedImageData, name: name.isEmpty ? "?" : name, size: 120)
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Capsule().stroke(Color.accentColor))
                    }
                    .padding(.top, 10)
                }
                
                // Name Entry
                TextField("Type name here...", text: $name)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 50)
                    .submitLabel(.done)
                
                Spacer()
                
                // Save Button
                Button {
                    createUser()
                } label: {
                    Text("Let's Draw!")
                        .font(.title3)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                }
                .disabled(!canSave)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // Logic to load the image data when picker selection changes
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    // Validation: Needs a name AND a photo (per your requirement)
    var canSave: Bool {
        !name.isEmpty && selectedImageData != nil
    }
    
    func createUser() {
        let newUser = User(name: name, profileImageData: selectedImageData)
        modelContext.insert(newUser)
        dismiss()
    }
}
