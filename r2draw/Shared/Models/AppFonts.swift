//
//  AppFonts.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import Foundation

struct StickerFont: Identifiable, Hashable {
    let id = UUID()
    let displayName: String
    let fontName: String // The actual system name or filename
    
    static let all: [StickerFont] = [
        StickerFont(displayName: "Normal", fontName: "SF Pro Rounded"),
        StickerFont(displayName: "Cursive", fontName: "JWCo.Marker-Regular"),
        StickerFont(displayName: "Serif", fontName: "PerfectlyNineties-Regular"),
        StickerFont(displayName: "Droid", fontName: "Sacul"),
        // Replace the strings above with your custom font filenames if needed
    ]
}
