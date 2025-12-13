//
//  CanvasView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import SwiftUI

struct CanvasView: View {
    let currentImage: UIImage?
    let isGenerating: Bool
    let onPrint: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background Card
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8)
            
            // 1. Image loaded
            if let currentImage {
                Image(uiImage: currentImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(4)
                
                // Floating Print Button
                Button(action: onPrint) {
                    Image(systemName: "printer.full")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding(16)
            }
            
            // 2. Loading
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
            
            // 3. Empty placeholder
            else {
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 50))
                        .foregroundStyle(.tertiary)
                    Text("Press and HOLD the mic to describe your image!")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Force 2:3 Aspect Ratio for 4x6" stickers
        aspectRatio(2.0/3.0, contentMode: .fit)
    }
}
