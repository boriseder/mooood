//
//  MoodButton.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//
import SwiftUI

// MARK: - Emoji Button
struct EmojiButton: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(DSText.detail)
                .frame(maxWidth: .infinity)
                .frame(height: DSLayout.miniCover)
                .background(
                    RoundedRectangle(cornerRadius: DSCorners.tight)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DSCorners.tight)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
