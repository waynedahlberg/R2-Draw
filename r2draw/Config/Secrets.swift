//
//  Secrets.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import Foundation

// MARK: - Application secrets
struct Secrets {
    // Replace this string with your actual Google Gemini API Key
    static let geminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
    
    // Simple validation to ensure we don't run with a placeholder
    static var isValid: Bool {
        return geminiAPIKey != "YOUR_GEMINI_API_KEY_HERE" && !geminiAPIKey.isEmpty
    }
}
