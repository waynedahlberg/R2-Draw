//
//  MainView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Data
    let user: User
    var onSwitchUser: (User) -> Void
    
    @Query(sort: \User.createdAt, order: .reverse) private var allUsers: [User]
    // Note: We do NOT query stickers here to prevent blocking. The Gallery strip handles it.
    
    // MARK: - Services
    @Bindable var speechRecognizer: SpeechRecognizer
    @Bindable var printerService: PrinterService
    private let geminiService = GeminiService()
    
    // MARK: - Local State
    @State private var isRecording = false
    @State private var isGenerating = false
    @State private var currentImage: UIImage?
    @State private var lastPrompt: String = ""
    @State private var errorMessage: String?
    
    // Sheets
    @State private var showUserSwitcher = false
    @State private var showPrinterSheet = false
    @State private var showFontPicker = false
    @State private var stickerToDelete: Sticker?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // 1. Canvas
                CanvasView(
                    currentImage: currentImage,
                    isGenerating: isGenerating,
                    onPrint: {
                        if let img = currentImage {
                            printerService.printImage(img)
                        }
                    }
                )
                .padding(.horizontal)
                .padding(.top)
                
                // 2. Transcript
                TranscriptView(
                    text: isRecording ? speechRecognizer.transcript : lastPrompt,
                    isRecording: isRecording
                )
                
                Spacer()
                
                // 3. Controls
                RecordControlView(
                    isRecording: isRecording,
                    isReady: speechRecognizer.isReady,
                    isGenerating: isGenerating,
                    onStartRecording: startRecording,
                    onStopRecording: stopRecordingAndGenerate
                )
                
                // 4. Gallery (Lazy Loaded)
                StickerGalleryStrip(
                    userId: user.id,
                    onSelect: { sticker in
                        withAnimation {
                            currentImage = sticker.uiImage
                            lastPrompt = sticker.prompt
                        }
                    },
                    onDelete: { sticker in
                        stickerToDelete = sticker
                    }
                )
            }
            .navigationTitle("Magic Printer")
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: - Toolbar
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showUserSwitcher = true } label: {
                        UserAvatarView(imageData: user.profileImageData, name: user.name, size: 32)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showFontPicker = true } label: {
                            Image(systemName: "textformat")
                                .font(.footnote).bold()
                                .foregroundStyle(.secondary)
                                .padding(6)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                        
                        Button { showPrinterSheet = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: printerIcon)
                                if case .connected = printerService.state {
                                    Circle().fill(Color.green).frame(width: 6, height: 6)
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(printerColor)
                        }
                    }
                }
            }
            // MARK: - Sheets
            .sheet(isPresented: $showUserSwitcher) {
                UserSwitcherSheet(
                    users: allUsers,
                    currentUser: user,
                    onSwitch: { selectedUser in
                        showUserSwitcher = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwitchUser(selectedUser)
                        }
                    }
                )
            }
            .sheet(isPresented: $showPrinterSheet) { PrinterConnectionSheet(service: printerService) }
            .sheet(isPresented: $showFontPicker) { FontPickerSheet(user: user) }
            .confirmationDialog("Delete this sticker?", isPresented: Binding(get: { stickerToDelete != nil }, set: { if !$0 { stickerToDelete = nil } }), titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteSticker() }
                Button("Cancel", role: .cancel) { stickerToDelete = nil }
            }
        }
        .onAppear {
            // Re-enable service scanning
            printerService.startScanning()
        }
    }
    
    // MARK: - Helpers
    
    var printerIcon: String {
        switch printerService.state {
        case .connected: return "printer.fill"
        case .bluetoothOff: return "bluetooth.slash"
        case .error: return "exclamationmark.triangle.fill"
        default: return "printer"
        }
    }
    
    var printerColor: Color {
        switch printerService.state {
        case .connected: return .blue
        case .bluetoothOff, .error: return .red
        default: return .gray
        }
    }
    
    // MARK: - Actions
    
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
        let fontName = user.fontName
        
        Task {
            do {
                let rawData = try await geminiService.generateImage(from: prompt)
                
                if let rawImage = UIImage(data: rawData) {
                    
                    // Heavy processing on background
                    let finalImage = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                        return ImageProcessor.process(image: rawImage, watermarkText: watermarkName, fontName: fontName)
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
    
    func deleteSticker() {
        guard let sticker = stickerToDelete else { return }
        withAnimation {
            if currentImage == sticker.uiImage {
                currentImage = nil
                lastPrompt = ""
            }
            modelContext.delete(sticker)
        }
        stickerToDelete = nil
    }
}
