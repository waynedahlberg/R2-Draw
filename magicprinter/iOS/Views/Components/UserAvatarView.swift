//
//  UserAvatarView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI

struct UserAvatarView: View {
    // CHANGE: Accept UIImage directly (already decoded)
    let uiImage: UIImage?
    let name: String
    let size: CGFloat
    
    // Convenience init for raw data (only used in lists where it doesn't change often)
    init(imageData: Data?, name: String, size: CGFloat) {
        if let data = imageData {
            self.uiImage = UIImage(data: data)
        } else {
            self.uiImage = nil
        }
        self.name = name
        self.size = size
    }
    
    // Convenience init for when we already have the image (Optimized)
    init(uiImage: UIImage?, name: String, size: CGFloat) {
        self.uiImage = uiImage
        self.name = name
        self.size = size
    }
    
    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
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
    }
}
