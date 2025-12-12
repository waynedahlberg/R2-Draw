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
    
    // MARK: - Data & Config
    let user: User
    var onSwitchUser: (User) -> Void
    
    @Query(sort: \User.createdAt, order: .reverse) private var allUsers: [User]
    @Query(sort: \Sticker.dateCreated, order: .reverse) private var allStickers: [Sticker]
    
    // MARK: - Services
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var printerService = PrinterService()
    private let geminiService = GeminiService()
    
    // MARK: - Local State
    @State private var isRecording = false
    @State private var isGenerating = false
    @State private var currentImage: UIImage?
    @State private var lastPrompt: String = ""
    @State private var errorMessage: String?
    
    // Sheets & Alerts
    @State private var showUserSwitcher = false
    @State private var showPrinterSheet = false
    @State private var showFontPicker = false
    @State private var stickerToDelete: Sticker?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // MARK: 1. Canvas / Preview Area
                ZStack(alignment: .bottomTrailing) {
                    
                    // Background Card
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10)
                    
                    // State: Image Loaded
                    if let currentImage {
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .padding(8) // Inset to show the "card" edge
                        
                        // Floating Print Button
                        Button {
                            printerService.printImage(currentImage)
                        } label: {
                            Image(systemName: "printer.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4, y: 2)
                        }
                        .padding(20)
                    }
                    // State: Loading
                    else if isGenerating {
                        VStack {
                            ProgressView().scaleEffect(2)
                            Text("Dreaming...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    // State: Empty / Placeholder
                    else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 50))
                                .foregroundStyle(.tertiary)
                            Text("Press the mic to dream!")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                // Force 2:3 Aspect Ratio (4x6 Sticker format)
                .aspectRatio(2.0/3.0, contentMode: .fit)
                .padding(.horizontal)
                .padding(.top)
                
                // MARK: 2. Transcript Display
                Text(isRecording ? speechRecognizer.transcript : lastPrompt)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(height: 80)
                    .padding(.horizontal)
                    .animation(.default, value: speechRecognizer.transcript)
                
                Spacer()
                
                // MARK: 3. The Big Mic Button
                Button {
                    // Action handled by DragGesture below
                } label: {
                    ZStack {
                        // Pulse Effect Background
                        if isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .scaleEffect(1.2)
                                .transition(.opacity)
                        }
                        
                        // Main Button Circle
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 80, height: 80)
                            .shadow(radius: 4, y: 2)
                        
                        // Icon
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
                
                Text(isRecording ? "Listening..." : "Hold to speak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
                
                // MARK: 4. Recent Stickers Gallery
                if !userStickers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(userStickers) { sticker in
                                if let uiImage = sticker.uiImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        // 2:3 Thumbnail Ratio (80w x 120h)
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
                                        .onLongPressGesture {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                            stickerToDelete = sticker
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 130)
                    .padding(.bottom)
                }
            }
            .navigationTitle("R2 Draw")
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: - Toolbar Items
            .toolbar {
                // Leading: User Profile Switcher
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showUserSwitcher = true
                    } label: {
                        UserAvatarView(imageData: user.profileImageData, name: user.name, size: 32)
                    }
                }
                
                // Trailing Group: Font Picker + Printer Status
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Font Picker
                        Button {
                            showFontPicker = true
                        } label: {
                            Image(systemName: "textformat")
                                .font(.footnote)
                                .bold()
                                .foregroundStyle(.secondary)
                                .padding(6)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                        
                        // Printer Status
                        Button {
                            showPrinterSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: printerIcon)
                                if case .connected = printerService.state {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(printerColor)
                        }
                    }
                }
            }
        }
        // MARK: - Lifecycle
        .onAppear {
            printerService.startScanning()
        }
        // MARK: - Sheets
        .sheet(isPresented: $showUserSwitcher) {
            userSwitcherSheet
        }
        .sheet(isPresented: $showPrinterSheet) {
            PrinterConnectionSheet(service: printerService)
        }
        .sheet(isPresented: $showFontPicker) {
            FontPickerSheet(user: user)
        }
        // MARK: - Delete Dialog
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
    
    // MARK: - Helper Views & Logic
    
    // User Switcher Content (Extracted to keep body clean)
    var userSwitcherSheet: some View {
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
                    
                    Button {
                        showUserSwitcher = false
                        onSwitchUser(User(name: "", profileImageData: nil))
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
                .padding(.bottom, 50)
            }
        }
        .presentationDetents([.fraction(0.4), .medium])
        .presentationDragIndicator(.visible)
    }
    
    // Printer UI Helpers
    var printerIcon: String {
        switch printerService.state {
        case .connected: return "printer.fill"
        case .bluetoothOff: return "antenna.radiowaves.left.and.right.slash"
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
    
    // Logic Helpers
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
        
        // Capture simple strings for thread safety (Swift 6)
        let watermarkName = user.name
        let fontName = user.fontName
        
        Task {
            do {
                let rawData = try await geminiService.generateImage(from: prompt)
                
                if let rawImage = UIImage(data: rawData) {
                    
                    // Heavy processing on background thread
                    let finalImage = await Task.detached(priority: .userInitiated) {
                        return ImageProcessor.process(image: rawImage, watermarkText: watermarkName, fontName: fontName)
                    }.value
                    
                    guard let processedImage = finalImage,
                          let processedData = processedImage.pngData() else {
                        throw GeminiError.noData
                    }
                    
                    // Update UI on Main Actor
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
