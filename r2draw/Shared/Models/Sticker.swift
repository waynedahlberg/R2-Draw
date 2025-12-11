//
//  Sticker.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Sticker Model
@Model
final class Sticker {
    var id: UUID
    var prompt: String
    @Attribute(.externalStorage) var imageData: Data?
    var dateCreated: Date
    var isFavorite: Bool
    
    // Relationship: A sticker belongs to one User
    var creator: User?
    
    init(prompt: String, imageData: Data, creator: User) {
        self.id = UUID()
        self.prompt = prompt
        self.imageData = imageData
        self.dateCreated = Date()
        self.isFavorite = false
        self.creator = creator
    }
}

// MARK: - Sticker Helpers
extension Sticker {
    /// Helper to get the UIImage easily for sharing/printing
    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}
