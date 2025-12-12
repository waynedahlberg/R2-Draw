//
//  TSPLGenerator.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import UIKit

struct TSPLGenerator {
    
    // Generates the binary command data for a 4x6" TSPL Printer
    static func generate(image: UIImage) -> Data {
        var command = Data()
        
        // 1. Setup label size: (4x6 inches is 100mm x 150mm)
        // PM-241-BT is usually 203 DPI. 4 inches * 203 = ~812 dots wide
        let widthBytes = 100    // 800 dots / 8 bits = 100 bytes wide
        let pixelWidth = 800
        let pixelHeight = 1200  // 6 inches long
        
        // TSPL Setup commands
        // CLS: Clear buffer
        // SIZE 4,6: Set site to 4x6 printer
        // GAP 3 mm,0: Tell it there is a gap between labels
        // DIRECTION 1: Print top to bottom
        let setup = "CLS\r\nSIZE 4,6\r\nGAP 3 mm,0\r\nDIRECTION 1\r\n"
        command.append(setup.data(using: .utf8)!)
        
        // 2. Resize Image to fit printer width (800px)
        // We use the extension we made earlier , but forcing exact width
        let resized = image.resizeForThermal(width: CGFloat(pixelWidth))
        
        // 3. Convert Image to Monochrome Bitmap Data
        guard let inputCG = resized.cgImage else { return command }
        let context = createBitmapContext(width: pixelWidth, height: inputCG.height)
        context?.draw(inputCG, in: CGRect(x: 0, y: 0, width: pixelWidth, height: inputCG.height))
        
        guard let pixelData = context?.data else { return command }
        
        // 4. BITMAP Command
        // Syntax: BITMAP X,Y,width_in_bytes,height_in_dots,mode,data...
        let header = "BITMAP 0,0,\(widthBytes),\(inputCG.height),0,"
        command.append(header.data(using: .utf8)!)
        
        // 5. Loop through pixels and pack bits
        // Source is RGBA (4 bytes per pixel). We need 1 bit per pixel.
        let dataPointer = pixelData.bindMemory(to: UInt8.self, capacity: pixelWidth * inputCG.height * 4)
        var bitmapData = Data()
        
        for y in 0..<inputCG.height {
            for x in stride(from: 0, to: pixelWidth, by: 8) {
                var byte: UInt8 = 0
                for bit in 0..<8 {
                    if x + bit < pixelWidth {
                        let offset = (y * pixelWidth + (x + bit)) * 4
                        let r = dataPointer[offset]
                        // If pixel is dark (r < 128), set the bit to 1.
                        // TSPL: 1 = Black, 0 = White
                        if r > 128 {
                            byte |= (1 << (7 - bit))
                        }
                    }
                }
                bitmapData.append(byte)
            }
        }
        
        command.append(bitmapData)
        
        // 6. Print Command
        // PRINT 1: Print 1 copy
        command.append("\r\nPRINT 1\r\n".data(using: .utf8)!)
        
        return command
    }
    
    // Helper to create a clean context
    private static func createBitmapContext(width: Int, height: Int) -> CGContext? {
        return CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4, // 4 bytes per pixel (RGBA)
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }
}
