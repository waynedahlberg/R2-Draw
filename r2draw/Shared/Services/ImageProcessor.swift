//
//  ImageProcessor.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import UIKit // Explicitly import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct ImageProcessor {
    
    /// Changed signature: Accepts `watermarkText` (String) instead of `User` object.
    /// This fixes the "Non-Sendable" warning by avoiding passing the CoreData/SwiftData object between threads.
    static func process(image: UIImage, watermarkText: String) -> UIImage? {
        // 1. Add Watermark
        guard let watermarked = addWatermark(to: image, text: watermarkText) else { return nil }
        
        // 2. Convert to Black & White
        return applyHighContrast(to: watermarked)
    }
    
    // MARK: - Watermarking
    private static func addWatermark(to image: UIImage, text: String) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)
            
            // Configure Text
            let fontSize = image.size.width * 0.08
            
            // FIX: Create the Rounded Font correctly for UIKit
            let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            let font: UIFont
            if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
                font = UIFont(descriptor: descriptor, size: fontSize)
            } else {
                font = systemFont
            }
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black.withAlphaComponent(0.8),
                .strokeColor: UIColor.white,
                .strokeWidth: -4.0
            ]
            
            let attributedString = NSAttributedString(string: text.uppercased(), attributes: attributes)
            let textSize = attributedString.size()
            
            // Position: Top Right Corner
            let padding = image.size.width * 0.05
            let rect = CGRect(
                x: image.size.width - textSize.width - padding,
                y: padding,
                width: textSize.width,
                height: textSize.height
            )
            
            // Draw Text
            attributedString.draw(in: rect)
        }
    }
    
    // MARK: - B&W Filter
    private static func applyHighContrast(to inputImage: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: inputImage) else { return nil }
        let context = CIContext()
        
        let monochrome = CIFilter.photoEffectNoir()
        monochrome.inputImage = ciImage
        
        let controls = CIFilter.colorControls()
        controls.inputImage = monochrome.outputImage
        controls.contrast = 2.0
        controls.brightness = 0.1
        
        guard let outputImage = controls.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
