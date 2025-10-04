//
//  EnergyButton.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//
import SwiftUI

// MARK: - Energy Button
struct EnergyButton: View {
    let value: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "bolt.fill" : "bolt")
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .orange : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color(.systemGray6))
        }
        .buttonStyle(.plain)
    }
}
