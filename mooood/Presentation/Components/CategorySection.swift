//
//  CategorySection.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//
import SwiftUI

// MARK: - Category Section
struct CategorySection<Content: View>: View {
    let title: String
    let selectedValue: Int?
    let onSelect: (Int) -> Void
    let fillUpTo: Bool // true für Sterne/Energy, false für Emojis
    let content: (Int, Bool, @escaping () -> Void) -> Content
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { value in
                    let isSelected = if fillUpTo {
                        selectedValue != nil && value <= selectedValue!
                    } else {
                        selectedValue == value
                    }
                    
                    content(value, isSelected) {
                        onSelect(value)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
