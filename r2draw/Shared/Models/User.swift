//
//  User.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - User Model
@Model
final class User {
    var id: UUID
    var name: String
    @Attribute(.externalStorage) var profileImageData: Data? // Store bulky images externally if needed
    var createdAt: Date
    
    // Relationship: One User has Many Stickers
    // DeleteRule .cascade means if we delete the User, their stickers go too.
    @Relationship(deleteRule: .cascade, inverse: \Sticker.creator)
    var stickers: [Sticker]?
    
    init(name: String, profileImageData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.profileImageData = profileImageData
        self.createdAt = Date()
        self.stickers = []
    }
}

// MARK: - User Helpers
extension User {
    /// Returns a SwiftUI Image from the stored data, or a placeholder
    var profileImage: Image {
        if let data = profileImageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "person.crop.circle.fill")
        }
    }
}
