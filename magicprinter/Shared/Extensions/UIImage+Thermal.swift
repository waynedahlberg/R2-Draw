//
//  UIImage+Thermal.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import UIKit

extension UIImage {
    func resizeForThermal(width: CGFloat) -> UIImage {
        let aspectRatio = self.size.height / self.size.width
        let height = width * aspectRatio
        let newSize = CGSize(width: width, height: height)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1    // 1:1 pixel mapping is crucial for thermal
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
