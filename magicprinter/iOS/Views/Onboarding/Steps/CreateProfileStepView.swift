//
//  CreateProfileStepView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/13/25.
//

import SwiftUI
import PhotosUI
import SwiftData

struct CreateProfileStepView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Callback to tell the container "We are done!"
    var onComplete: (User) -> Void
    
    @State private var name: String = ""
    @State private var selectedItem: PhotosPickerItem?
    
    // UI State
    @State private var thumbnailImage: UIImage?
    @State private var isLoadingImage = false
    @State private var isSaving = false
    @State private var readyToSaveData: Data?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("One Last Thing...")
                .font(.largeTitle)
                .bold()
            
            VStack {
                // Avatar Preview
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
                            .overlay(Image(systemName: "camera.fill").font(.title).foregroundStyle(.gray))
                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    }
                    
                    if isLoadingImage {
                        ZStack {
                            Circle().fill(.black.opacity(0.3))
                            ProgressView().tint(.white)
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                    }
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Choose Photo")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 24)
                        .background(Capsule().stroke(Color.blue, lineWidth: 1))
                }
                .padding(.top, 10)
                .disabled(isLoadingImage)
            }
            
            TextField("What is your name?", text: $name)
                .font(.title)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                .padding(.horizontal, 40)
                .submitLabel(.done)
            
            Spacer()
            
            OnboardingButton(
                title: "Let's Draw!",
                icon: "sparkles",
                action: saveUser,
                isLoading: isSaving
            )
            .disabled(!canSave)
            .padding(.bottom, 50)
        }
        // Background Image Processing (The "Snappy" Logic)
        .onChange(of: selectedItem) {
            guard let item = selectedItem else { return }
            isLoadingImage = true
            thumbnailImage = nil
            
            Task.detached(priority: .userInitiated) {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let rawImage = UIImage(data: data),
                      // Ensure you have the UIImage+Extensions.swift file for .resized()
                      let downsampled = rawImage.resized(maxDimension: 300),
                      let optimizedData = downsampled.jpegData(compressionQuality: 0.7)
                else {
                    await MainActor.run { isLoadingImage = false }
                    return
                }
                
                await MainActor.run {
                    self.thumbnailImage = downsampled
                    self.readyToSaveData = optimizedData
                    self.isLoadingImage = false
                }
            }
        }
    }
    
    var canSave: Bool {
        !name.isEmpty && thumbnailImage != nil && readyToSaveData != nil
    }
    
    func saveUser() {
        guard let data = readyToSaveData else { return }
        isSaving = true
        
        let newUser = User(name: name, profileImageData: data)
        modelContext.insert(newUser)
        // We explicitly save here to ensure the ID is generated
        try? modelContext.save()
        
        // Notify the app that we are finished
        onComplete(newUser)
    }
}
