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
    @Query(sort: \Sticker.dateCreated, order: .reverse) private var allStickers: [Sticker]
    let user: User
    
    // Services
    @State private var speechRecognizer = SpeechRecognizer()
    private let geminiService = GeminiService()
    
    // State
    @State private var isRecording = false
    @State private var isGenerating = false
    @State private var currentImage: UIImage?
    @State private var lastPrompt: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // 1. The Canvas / Result Area
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10)
                    
                    if let currentImage {
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .padding()
                    } else if isGenerating {
                        ProgressView()
                            .scaleEffect(2)
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
                .aspectRatio(1.0, contentMode: .fit)
                .padding()
                
                // 2. Transcript Display
                Text(isRecording ? speechRecognizer.transcript : lastPrompt)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .frame(height: 80)
                    .padding(.horizontal)
                    .animation(.default, value: speechRecognizer.transcript)
                
                Spacer()
                
                // 3. The Big Button
                Button {
                    // Action handled by DragGesture below
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
                        .onChanged { _ in
                            if !isRecording && !isGenerating {
                                startRecording()
                            }
                        }
                        .onEnded { _ in
                            if isRecording {
                                stopRecordingAndGenerate()
                            }
                        }
                )
                .disabled(isGenerating)
                
                if !userStickers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(userStickers) { sticker in
                                if let uiImage = sticker.uiImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            self.currentImage = uiImage
                                            self.lastPrompt = sticker.prompt
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                    .padding(.bottom)
                }
                
                Text(isRecording ? "Listening..." : "Hold to speak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 30)
            }
            .navigationTitle("R2 Draw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    UserAvatarView(imageData: user.profileImageData, name: user.name, size: 32)
                }
            }
        }
    }
    
    // MARK: - Logic
    
    func startRecording() {
        withAnimation {
            isRecording = true
            errorMessage = nil
            currentImage = nil // Clear previous image while recording new one? Or keep it?
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
        
        // FIX: Extract the name here, on the Main Actor, before the task starts.
        let watermarkName = user.name
        
        Task {
            do {
                let rawData = try await geminiService.generateImage(from: prompt)
                
                if let rawImage = UIImage(data: rawData) {
                    
                    // MARK: - Process Image
                    // FIX: Pass the String 'watermarkName', not the 'user' object.
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
    
    var userStickers: [Sticker] {
        allStickers.filter { $0.creator?.id == user.id }
    }
}
