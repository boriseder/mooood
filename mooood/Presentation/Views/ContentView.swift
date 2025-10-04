//
//  ContentView.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//

import SwiftUI
import SwiftData

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]
    @State private var showHistory = false
    
    var todayEntry: DailyEntry {
        if let existing = entries.first(where: { Calendar.current.isDateInToday($0.date) }) {
            return existing
        } else {
            let entry = DailyEntry(date: Date.now)
            modelContext.insert(entry)
            return entry
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Date display
                    Text(Date.now.formatted(date: .complete, time: .omitted))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.top)
                    
                    // I feel...
                    CategorySection(
                        title: "I feel",
                        selectedValue: todayEntry.mood,
                        onSelect: { value in
                            todayEntry.mood = value
                            saveEntry()
                        },
                        fillUpTo: false,
                        content: { value, isSelected, action in
                            EmojiButton(
                                emoji: MoodEmoji(rawValue: value)?.emoji ?? "",
                                isSelected: isSelected,
                                action: action
                            )
                        }
                    )
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // I slept...
                    CategorySection(
                        title: "I slept",
                        selectedValue: todayEntry.sleep,
                        onSelect: { value in
                            todayEntry.sleep = value
                            saveEntry()
                        },
                        fillUpTo: true,
                        content: { value, isSelected, action in
                            StarButton(
                                value: value,
                                isSelected: isSelected,
                                action: action
                            )
                        }
                    )
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // I ate...
                    CategorySection(
                        title: "I ate",
                        selectedValue: todayEntry.nutrition,
                        onSelect: { value in
                            todayEntry.nutrition = value
                            saveEntry()
                        },
                        fillUpTo: true,
                        content: { value, isSelected, action in
                            StarButton(
                                value: value,
                                isSelected: isSelected,
                                action: action
                            )
                        }
                    )
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // My energy level
                    CategorySection(
                        title: "My energy level",
                        selectedValue: todayEntry.energy,
                        onSelect: { value in
                            todayEntry.energy = value
                            saveEntry()
                        },
                        fillUpTo: true,
                        content: { value, isSelected, action in
                            EnergyButton(
                                value: value,
                                isSelected: isSelected,
                                action: action
                            )
                        }
                    )
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        TextEditor(text: Binding(
                            get: { todayEntry.notes ?? "" },
                            set: { todayEntry.notes = $0.isEmpty ? nil : $0; saveEntry() }
                        ))
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(entries: entries)
            }
        }
    }
    
    private func saveEntry() {
        try? modelContext.save()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
