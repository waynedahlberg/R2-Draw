//
//  MainView.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    
    // DATA
    let user: User
    var onSwitchUser: (User) -> Void // Logic to change the app-level user
    
    @Query(sort: \User.createdAt, order: .reverse) private var allUsers: [User]
    @Query(sort: \Sticker.dateCreated, order: .reverse) private var allStickers: [Sticker]
    
    // SERVICES
    @State private var speechRecognizer = SpeechRecognizer()
    private let geminiService = GeminiService()
    
    // STATE
    @State private var isRecording = false
    @State private var isGenerating = false
    @State private var currentImage: UIImage?
    @State private var lastPrompt: String = ""
    @State private var errorMessage: String?
    
    // SHEETS
    @State private var showUserSwitcher = false
    @State private var stickerToDelete: Sticker? // Holds the sticker we want to kill
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // 1. Canvas Area
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10)
                    
                    if let currentImage {
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .padding(8)
                    } else if isGenerating {
                        ProgressView().scaleEffect(2)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 50))
                                .foregroundStyle(.tertiary)
                            Text("Press the mic to dream!")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .aspectRatio(2.0/3.0, contentMode: .fit)
                .padding()
                
                // 2. Transcript
                Text(isRecording ? speechRecognizer.transcript : lastPrompt)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .frame(height: 80)
                    .padding(.horizontal)
                    .animation(.default, value: speechRecognizer.transcript)
                
                Spacer()
                
                // 3. Record Button
                Button {
                    // Handled by gesture
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 80, height: 80)
                            .shadow(radius: 4)
                        
                        Image(systemName: isRecording ? "waveform" : "mic.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .scaleEffect(isRecording ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isRecording)
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !isRecording && !isGenerating { startRecording() } }
                        .onEnded { _ in if isRecording { stopRecordingAndGenerate() } }
                )
                .disabled(isGenerating)
                
                Text(isRecording ? "Listening..." : "Hold to speak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
                
                // 4. Gallery Strip
                if !userStickers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(userStickers) { sticker in
                                if let uiImage = sticker.uiImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            withAnimation {
                                                self.currentImage = uiImage
                                                self.lastPrompt = sticker.prompt
                                            }
                                        }
                                        // MARK: - Long Press to Delete
                                        .onLongPressGesture {
                                            stickerToDelete = sticker
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 120)
                    .padding(.bottom)
                }
            }
            .navigationTitle("R2 Draw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // MARK: - User Switcher Trigger
                    Button {
                        showUserSwitcher = true
                    } label: {
                        UserAvatarView(imageData: user.profileImageData, name: user.name, size: 32)
                    }
                }
            }
        }
        // MARK: - User Switcher Sheet
        .sheet(isPresented: $showUserSwitcher) {
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top)
                
                Text("Switch Dreamer")
                    .font(.headline)
                    .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(allUsers) { otherUser in
                            Button {
                                showUserSwitcher = false
                                // Small delay to let sheet dismiss before switching context
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onSwitchUser(otherUser)
                                }
                            } label: {
                                HStack {
                                    UserAvatarView(imageData: otherUser.profileImageData, name: otherUser.name, size: 50)
                                    
                                    Text(otherUser.name)
                                        .font(.title3)
                                        .bold()
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    if otherUser.id == user.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(16)
                            }
                        }
                        
                        // Option to add new user
                        Button {
                            showUserSwitcher = false
                            onSwitchUser(User(name: "", profileImageData: nil)) // Hack: Trigger "Logged Out" state
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(width: 50, height: 50)
                                    .overlay(Image(systemName: "plus"))
                                
                                Text("Add New Dreamer")
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 50) // Ample vertical padding
                }
            }
            .presentationDetents([.fraction(0.4), .medium]) // Dynamic height
            .presentationDragIndicator(.visible)
        }
        // MARK: - Delete Confirmation
        .confirmationDialog(
            "Delete this sticker?",
            isPresented: Binding(
                get: { stickerToDelete != nil },
                set: { if !$0 { stickerToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let sticker = stickerToDelete {
                    withAnimation {
                        // If we are looking at the one we deleted, clear the screen
                        if currentImage == sticker.uiImage {
                            currentImage = nil
                            lastPrompt = ""
                        }
                        modelContext.delete(sticker)
                    }
                }
                stickerToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                stickerToDelete = nil
            }
        }
    }
    
    // Logic (Keeping existing methods...)
    var userStickers: [Sticker] {
        allStickers.filter { $0.creator?.id == user.id }
    }
    
    func startRecording() {
        withAnimation {
            isRecording = true
            errorMessage = nil
        }
        speechRecognizer.startTranscribing()
    }
    
    func stopRecordingAndGenerate() {
        withAnimation { isRecording = false }
        speechRecognizer.stopTranscribing()
        
        let prompt = speechRecognizer.transcript
        guard !prompt.isEmpty else { return }
        lastPrompt = prompt
        generateImage(prompt: prompt)
    }
    
    func generateImage(prompt: String) {
        isGenerating = true
        let watermarkName = user.name
        
        Task {
            do {
                let rawData = try await geminiService.generateImage(from: prompt)
                
                if let rawImage = UIImage(data: rawData) {
                    let finalImage = await Task.detached(priority: .userInitiated) {
                        return ImageProcessor.process(image: rawImage, watermarkText: watermarkName)
                    }.value
                    
                    guard let processedImage = finalImage,
                          let processedData = processedImage.pngData() else {
                        throw GeminiError.noData
                    }
                    
                    await MainActor.run {
                        self.currentImage = processedImage
                        self.saveSticker(prompt: prompt, data: processedData)
                        self.isGenerating = false
                    }
                }
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    self.errorMessage = "Oops! Dream failed."
                    self.isGenerating = false
                }
            }
        }
    }
    
    func saveSticker(prompt: String, data: Data) {
        let sticker = Sticker(prompt: prompt, imageData: data, creator: user)
        modelContext.insert(sticker)
    }
}
