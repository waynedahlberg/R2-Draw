//
//  UIImage+Extensions.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import UIKit

extension UIImage {
    /// Resizes the image to a max dimension (e.g., 300px)
    /// Marked 'nonisolated' so it can be called from background threads
    nonisolated func resized(maxDimension: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        if size.width <= maxDimension && size.height <= maxDimension {
            return self
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Helper to get data without warnings
    nonisolated func optimizedData(compression: CGFloat = 0.7) -> Data? {
        return self.jpegData(compressionQuality: compression)
    }
}
