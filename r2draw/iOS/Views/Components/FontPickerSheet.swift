//
//  FontPickerSheet.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import SwiftUI

struct FontPickerSheet : View {
    @Bindable var user: User
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(StickerFont.all) { fontOption in
                Button {
                    user.fontName = fontOption.fontName
                    dismiss()
                } label: {
                    HStack {
                        Text(user.name.isEmpty ? "Preview" : user.name)
                            .font(.custom(fontOption.fontName, size: 24))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if user.fontName == fontOption.fontName {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Choose signature")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
