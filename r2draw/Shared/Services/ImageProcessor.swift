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
            
            // B. Place the Gemini Image (ASPECT FILL)
            // We want to fill the HEIGHT (1800).
            // Since the source is 3:4, if height is 1800, width becomes 1350.
            // Our canvas is only 1200 wide, so we center it (-75 x offset).
            
            let targetHeight = canvasHeight
            let targetWidth = targetHeight * (3.0/4.0) // Maintain 3:4 aspect ratio of source
            
            // Center the image horizontally
            let xOffset = (canvasWidth - targetWidth) / 2
            
            let artRect = CGRect(
                x: xOffset,
                y: 0, // Start at the very top
                width: targetWidth,
                height: targetHeight
            )
            
            image.draw(in: artRect)
            
            // C. Border REMOVED
            
            // D. Add Watermark (Bottom Right, subtle)
            let fontSize = canvasHeight * 0.03
            
            let font: UIFont
            if fontName == "SF Pro Rounded" {
                if let descriptor = UIFont.systemFont(ofSize: fontSize, weight: .bold).fontDescriptor.withDesign(.rounded) {
                    font = UIFont(descriptor: descriptor, size: fontSize)
                } else {
                    font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                }
            } else if let customFont = UIFont(name: fontName, size: fontSize) {
                font = customFont
            } else {
                font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            }
            
            // Add a white stroke around text to ensure readability if it overlaps art
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black,
                .strokeColor: UIColor.white,
                .strokeWidth: -3.0, // Negative for stroke AND fill
                .kern: 2.0
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
    
    // MARK: - B&W Filter (Unchanged)
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
