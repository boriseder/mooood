//
//  MoooodEntry.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//


import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Entry
struct MoooodEntry: TimelineEntry {
    let date: Date
    let hasEntry: Bool
    let mood: Int?
    let sleep: Int?
    let nutrition: Int?
    let energy: Int?
}

// MARK: - Timeline Provider
struct MoooodProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoooodEntry {
        MoooodEntry(date: Date(), hasEntry: false, mood: nil, sleep: nil, nutrition: nil, energy: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MoooodEntry) -> Void) {
        let entry = MoooodEntry(date: Date(), hasEntry: false, mood: nil, sleep: nil, nutrition: nil, energy: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MoooodEntry>) -> Void) {
        // In a real implementation, you'd fetch the data from App Groups shared container
        // For now, we'll create a simple entry
        let entry = MoooodEntry(
            date: Date(),
            hasEntry: false,
            mood: nil,
            sleep: nil,
            nutrition: nil,
            energy: nil
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct MoooodWidgetView: View {
    var entry: MoooodEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        Link(destination: URL(string: "mooood://daily-checkin")!) {
            content
        }
    }
    
    var content: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "face.smiling.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Daily Check-in")
                    .font(.headline)
                
                Spacer()
            }
            
            if entry.hasEntry {
                // Show progress
                VStack(alignment: .leading, spacing: 8) {
                    progressRow(icon: "face.smiling", value: entry.mood, color: .blue)
                    progressRow(icon: "moon.stars.fill", value: entry.sleep, color: .purple)
                    progressRow(icon: "fork.knife", value: entry.nutrition, color: .green)
                    progressRow(icon: "bolt.fill", value: entry.energy, color: .orange)
                }
            } else {
                // Prompt to log
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue.opacity(0.3))
                    
                    Text("Tap to log today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func progressRow(icon: String, value: Int?, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)
            
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .fill(value != nil && index <= value! ? color : Color.gray.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}


// MARK: - Widget Configuration
struct MoooodWidget: Widget {
    let kind: String = "MoooodWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoooodProvider()) { entry in
            MoooodWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Check-in")
        .description("Quick view of your daily entry")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    MoooodWidget()
} timeline: {
    MoooodEntry(date: Date(), hasEntry: false, mood: nil, sleep: nil, nutrition: nil, energy: nil)
    MoooodEntry(date: Date(), hasEntry: true, mood: 4, sleep: 5, nutrition: 3, energy: 4)
}
