//
//  ImageProcessor.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct ImageProcessor {
    
    /// Main processing function: Watermark -> Resize -> B&W Conversion
    static func process(image: UIImage, watermarkText: String, fontName: String) -> UIImage? {
        
        // 1. Create a 2:3 Canvas (4x6 format)
        let canvasWidth: CGFloat = 1200
        let canvasHeight: CGFloat = 1800 // 2:3 ratio
        let canvasSize = CGSize(width: canvasWidth, height: canvasHeight)
        
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        let compositedImage = renderer.image { context in
            // A. Draw White Background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
            
            // B. Place the Gemini Image
            let artWidth = canvasWidth * 0.9
            let artHeight = artWidth * (4.0/3.0)
            
            let artRect = CGRect(
                x: (canvasWidth - artWidth) / 2,
                y: canvasWidth * 0.05,
                width: artWidth,
                height: artHeight
            )
            
            image.draw(in: artRect)
            
            // C. Border REMOVED (Intentionally left blank)
            
            // D. Add Watermark
            // Scale font down significantly (3% of height)
            let fontSize = canvasHeight * 0.03
            
            // LOGIC: Try to create the custom font, fall back to System if it fails
            let font: UIFont
            if fontName == "SF Pro Rounded" {
                // Special handling for our "Default" look
                if let descriptor = UIFont.systemFont(ofSize: fontSize, weight: .bold).fontDescriptor.withDesign(.rounded) {
                    font = UIFont(descriptor: descriptor, size: fontSize)
                } else {
                    font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                }
            } else if let customFont = UIFont(name: fontName, size: fontSize) {
                font = customFont
            } else {
                // Fallback if custom font filename is wrong
                print("⚠️ Could not load font: \(fontName), using system.")
                font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            }
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black,
                .kern: 2.0 // Letter spacing
            ]
            
            let attributedString = NSAttributedString(string: watermarkText.uppercased(), attributes: attributes)
            let textSize = attributedString.size()
            
            // Position: Bottom Right Corner with padding
            let padding: CGFloat = 60
            
            let textRect = CGRect(
                x: canvasWidth - textSize.width - padding,
                y: canvasHeight - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedString.draw(in: textRect)
        }
        
        // 2. Convert to Black & White for Printer
        return applyHighContrast(to: compositedImage)
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
