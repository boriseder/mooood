//
//  MoodEntry.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//
import SwiftUI
import SwiftData

// MARK: - Model
@Model
final class DailyEntry {
    var date: Date
    var mood: Int?
    var sleep: Int?
    var nutrition: Int?
    var energy: Int?
    var notes: String?

    init(date: Date, mood: Int? = nil, sleep: Int? = nil, nutrition: Int? = nil, energy: Int? = nil) {
        self.date = date
        self.mood = mood
        self.sleep = sleep
        self.nutrition = nutrition
        self.energy = energy
        self.notes = notes
    }
    
    var isComplete: Bool {
        mood != nil && sleep != nil && nutrition != nil && energy != nil
    }
}

enum MoodEmoji: Int, CaseIterable {
    case veryBad = 1, bad, neutral, good, veryGood
    
    var emoji: String {
        switch self {
        case .veryBad: return "😢"
        case .bad: return "☹️"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .veryGood: return "😄"
        }
    }
}
