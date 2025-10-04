//
//  StarButton.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//
import SwiftUI

// MARK: - Star Button
struct StarButton: View {
    let value: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "star.fill" : "star")
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .yellow : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color(.systemGray6))
        }
        .buttonStyle(.plain)
    }
}
