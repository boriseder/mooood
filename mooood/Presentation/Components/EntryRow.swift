//
//  EntryRow.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//
import SwiftUI

// MARK: - Entry Row
struct EntryRow: View {
    let entry: DailyEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
            
            HStack(spacing: 16) {
                Label("\(entry.mood ?? 0)", systemImage: "face.smiling")
                    .font(.caption)
                Label("\(entry.sleep ?? 0)", systemImage: "bed.double")
                    .font(.caption)
                Label("\(entry.nutrition ?? 0)", systemImage: "fork.knife")
                    .font(.caption)
                Label("\(entry.energy ?? 0)", systemImage: "bolt")
                    .font(.caption)
           
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}
