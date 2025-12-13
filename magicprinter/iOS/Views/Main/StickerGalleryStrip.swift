//
//  StickerGalleryStrip.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import SwiftUI
import SwiftData

struct StickerGalleryStrip: View {
    // Instead of passing [Sticker], we pass the ID and let the view fetch
    @Query private var stickers: [Sticker]
    let onSelect: (Sticker) -> Void
    let onDelete: (Sticker) -> Void
    
    init(userId: UUID, onSelect: @escaping (Sticker) -> Void, onDelete: @escaping (Sticker) -> Void) {
        self.onSelect = onSelect
        self.onDelete = onDelete
        
        // DYNAMIC QUERY: Only fetch stickers for THIS user, sorted by date
        let filter = #Predicate<Sticker> { sticker in
            sticker.creator?.id == userId
        }
        _stickers = Query(filter: filter, sort: \Sticker.dateCreated, order: .reverse)
    }
    
    var body: some View {
        if !stickers.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stickers) { sticker in
                        // Because of Step 1, accessing sticker.uiImage here
                        // causes a small disk read, but it's much lighter than before.
                        if let uiImage = sticker.uiImage {
                            StickerThumbnail(uiImage: uiImage)
                                .onTapGesture { onSelect(sticker) }
                                .onLongPressGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    onDelete(sticker)
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 130)
            .padding(.bottom)
        }
    }
}

// Extracted for performance (Drawing optimizations)
struct StickerThumbnail: View {
    let uiImage: UIImage
    
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}
