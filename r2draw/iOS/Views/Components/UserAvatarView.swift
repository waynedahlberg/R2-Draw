//
//  UserAvatarView.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI

struct UserAvatarView : View {
    let imageData: Data?
    let name: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Fallback for when they haven't picked a photo yet
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: size, height: size)
                
                Text(name.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            // Optional: Add a ring border
            Circle()
                .strokeBorder(.white, lineWidth: size * 0.05)
                .frame(width: size, height: size)
                .shadow(radius: 2)
        }
    }
}

#Preview {
    UserAvatarView(imageData: nil, name: "Denny", size: 100)
}
