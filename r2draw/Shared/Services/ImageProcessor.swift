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
            // 1. Create a 2:3 Canvas (4x6 format)
            // We define a high-res canvas width (e.g., 1200px wide -> 1800px tall)
            let canvasWidth: CGFloat = 1200
            let canvasHeight: CGFloat = 1800 // 2:3 ratio
            let canvasSize = CGSize(width: canvasWidth, height: canvasHeight)
            
            let renderer = UIGraphicsImageRenderer(size: canvasSize)
            
            let compositedImage = renderer.image { context in
                // A. Draw White Background (The Sticker Paper)
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: canvasSize))
                
                // B. Place the Gemini Image (3:4 aspect ratio)
                // We center it and leave space at the bottom for the name
                let artWidth = canvasWidth * 0.9  // 5% margin on sides
                let artHeight = artWidth * (4.0/3.0) // Maintain 3:4 aspect ratio of source
                
                let artRect = CGRect(
                    x: (canvasWidth - artWidth) / 2,
                    y: canvasWidth * 0.05, // 5% margin from top
                    width: artWidth,
                    height: artHeight
                )
                
                image.draw(in: artRect)
                
                // C. Draw a thick black border around the art (Comic book style)
                let borderPath = UIBezierPath(rect: artRect)
                borderPath.lineWidth = 12
                UIColor.black.setStroke()
                borderPath.stroke()
                
                // D. Add Watermark Name at the Bottom (in the whitespace)
                // This turns the extra space into a "Label"
                let fontSize = canvasHeight * 0.08
                let font = UIFont.systemFont(ofSize: fontSize, weight: .black) // Heavy font
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black,
                    .kern: 5.0 // Spaced out letters
                ]
                
                let attributedString = NSAttributedString(string: watermarkText.uppercased(), attributes: attributes)
                let textSize = attributedString.size()
                
                // Center text in the remaining space at the bottom
                let remainingSpaceStart = artRect.maxY
                let remainingHeight = canvasHeight - remainingSpaceStart
                
                let textRect = CGRect(
                    x: (canvasWidth - textSize.width) / 2,
                    y: remainingSpaceStart + (remainingHeight - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                
                attributedString.draw(in: textRect)
            }
            
            // 2. Convert to Black & White for Printer
            return applyHighContrast(to: compositedImage)
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
