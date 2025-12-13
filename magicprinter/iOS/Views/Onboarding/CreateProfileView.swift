//
//  CreateProfileView.swift
//  magicprinter
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
    
    // UI State
    @State private var thumbnailImage: UIImage?
    @State private var isLoadingImage = false // Spinner for the avatar specifically
    @State private var isSaving = false       // Spinner for the "Let's Draw" button
    
    // We hold the processed data in memory so we don't have to re-compress it on save
    @State private var readyToSaveData: Data?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("New Dreamer")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                VStack {
                    // 1. Avatar Preview
                    ZStack {
                        if let thumbnailImage {
                            Image(uiImage: thumbnailImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                        .foregroundStyle(.gray)
                                )
                                .overlay(
                                    Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Loading Indicator OVER the avatar
                        if isLoadingImage {
                            ZStack {
                                Circle().fill(.black.opacity(0.3))
                                ProgressView().tint(.white)
                            }
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                        }
                    }
                    
                    // 2. Picker
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("Choose Photo")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(Capsule().stroke(Color.blue, lineWidth: 1))
                    }
                    .padding(.top, 10)
                    .disabled(isLoadingImage) // Prevent double tapping
                }
                
                TextField("Type Name", text: $name)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal, 40)
                    .submitLabel(.done)
                
                Spacer()
                
                // 3. Save Button
                Button {
                    saveUser()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Let's Draw!")
                        }
                    }
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSave ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                }
                .disabled(!canSave || isSaving)
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // 4. THE FIX: Total Background Offload
            .onChange(of: selectedItem) {
                guard let item = selectedItem else { return }
                
                // A. Update UI state immediately on Main Actor
                isLoadingImage = true
                thumbnailImage = nil // clear old image to show loading state
                
                // B. Detach EVERYTHING else to background
                Task.detached(priority: .userInitiated) {
                    // 1. Load Data (I/O)
                    // We load safely here. If it fails, we catch it.
                    guard let data = try? await item.loadTransferable(type: Data.self) else {
                        await MainActor.run { isLoadingImage = false }
                        return
                    }
                    
                    // 2. Process (CPU Heavy)
                    // We resize immediately to 300px using the helper we created earlier.
                    // If you don't have the helper file, this will fail, so let me know.
                    // Assuming you have the UIImage+Extensions from before.
                    guard let rawImage = UIImage(data: data),
                          let downsampled = rawImage.resized(maxDimension: 300),
                          let optimizedData = downsampled.jpegData(compressionQuality: 0.7)
                    else {
                        await MainActor.run { isLoadingImage = false }
                        return
                    }
                    
                    // 3. Update UI (Main Actor)
                    await MainActor.run {
                        self.thumbnailImage = downsampled
                        self.readyToSaveData = optimizedData
                        self.isLoadingImage = false
                    }
                }
            }
        }
        .interactiveDismissDisabled(isSaving || isLoadingImage)
    }
    
    var canSave: Bool {
        !name.isEmpty && thumbnailImage != nil && readyToSaveData != nil
    }
    
    func saveUser() {
        guard let data = readyToSaveData else { return }
        isSaving = true
        
        // This is now super fast because we already did the work!
        let newUser = User(name: name, profileImageData: data)
        modelContext.insert(newUser)
        try? modelContext.save()
        
        isSaving = false
        dismiss()
    }
}
