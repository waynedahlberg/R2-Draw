//
//  Sticker.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import Foundation
import SwiftData
import UIKit

@Model
final class Sticker {
    var id: UUID
    var prompt: String
    
    // CHANGE: Add @Attribute(.externalStorage)
    // This tells SwiftData: "Save this big blob to a file, not the DB row."
    // It will now only load into RAM when you actually access 'imageData'.
    @Attribute(.externalStorage) var imageData: Data?
    
    var dateCreated: Date
    
    @Relationship var creator: User?
    
    init(prompt: String, imageData: Data, creator: User) {
        self.id = UUID()
        self.prompt = prompt
        self.imageData = imageData
        self.dateCreated = Date()
        self.creator = creator
    }
    
    // Computed property for easy UI access
    @Transient var uiImage: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
}
