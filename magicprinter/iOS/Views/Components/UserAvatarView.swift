//
//  UserAvatarView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI

struct UserAvatarView: View {
    let imageData: Data?
    let name: String
    let size: CGFloat
    
    @State private var decodedImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let decodedImage {
                Image(uiImage: decodedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
            } else {
                Circle()
                    .fill(Color.orange.gradient)
                    .frame(width: size, height: size)
                
                Text(name.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Circle()
                .strokeBorder(.white, lineWidth: size * 0.05)
                .frame(width: size, height: size)
                .shadow(radius: 2)
        }
        // This ensures decoding happens in the background automatically
        .task(id: imageData) {
            if let data = imageData {
                let image = await decodeInBackground(data: data)
                self.decodedImage = image
            }
            self.isLoading = false
        }
    }
    
    // Helper to decode safely off the main thread
    nonisolated func decodeInBackground(data: Data) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) {
            return UIImage(data: data)
        }.value
    }
}
