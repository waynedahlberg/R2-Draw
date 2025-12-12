//
//  GeminiService.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import Foundation
import UIKit

enum GeminiError: Error {
    case invalidURL
    case noData
    case apiError(String)
}

final class GeminiService {
    // We use the Imagen 3 endpoint
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-fast-generate-001:predict"
    func generateImage(from prompt: String) async throws -> Data {
        guard Secrets.isValid else {
            throw GeminiError.apiError("Missing API Key in Secrets.swift")
        }
        
        guard let url = URL(string: "\(endpoint)?key=\(Secrets.geminiAPIKey)") else {
            throw GeminiError.invalidURL
        }
        
        // 1. Engineering the Prompt for Thermal Printing
        // We wrap the kid's prompt in specific instructions for line art.
        let fullPrompt = """
                A full-bleed, edge-to-edge black and white line art illustration for a coloring book.
                The image features: \(prompt), simple children's coloring page line art, thick bold contour lines for main subject, low detail background with large open spaces, minimalist design, easy to color, distinct and chunky shapes. High contrast black ink on white paper. No tiny details, no hatching, no shading, no greyscale, clean vector style.
                
                CRITICAL COMPOSITION RULES:
                1. NO BORDERS: Do not draw any square frames, margins, or borders around the image. The artwork must extend all the way to the edges of the canvas.
                2. DETAILED BACKGROUND: Do not leave the background empty. Fill the entire scene with intricate, interesting environmental details suitable for coloring (e.g., trees, clouds, patterns, buildings, stars, textures).
                3. STYLE: Clean, crisp, uniform black lines on a white background. No shading, no greyscale, no sketchiness.
                
                The image should be highly detailed and immersive, giving the child many small shapes and textures to color in every part of the page.
                """
        
        // 2. JSON Body
        // Google Imagen API structure
        let parameters: [String: Any] = [
            "instances": [
                ["prompt": fullPrompt]
            ],
            "parameters": [
                "sampleCount": 1,
                "aspectRatio": "3:4" // Or "3:4" if you prefer portrait
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        // 3. Network Request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Debugging helper: print error if it fails
            if let errorText = String(data: data, encoding: .utf8) {
                print("Gemini API Error: \(errorText)")
            }
            throw GeminiError.apiError("Server returned error")
        }
        
        // 4. Parse Response
        // The API returns base64 encoded image data string
        let decodedResponse = try JSONDecoder().decode(ImagenResponse.self, from: data)
        
        guard let base64String = decodedResponse.predictions.first?.bytesBase64Encoded,
              let imageData = Data(base64Encoded: base64String) else {
            throw GeminiError.noData
        }
        
        return imageData
    }
}

// MARK: - Response Models
// Helper structs to parse the JSON
struct ImagenResponse: Decodable {
    let predictions: [ImagenPrediction]
}

struct ImagenPrediction: Decodable {
    let bytesBase64Encoded: String
    let mimeType: String
}
