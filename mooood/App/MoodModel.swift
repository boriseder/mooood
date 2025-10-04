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
    var activities: [String] = []

    init(date: Date, mood: Int? = nil, sleep: Int? = nil, nutrition: Int? = nil, energy: Int? = nil, activities: [String] = [], notes: String? = nil) {
        self.date = date
        self.mood = mood
        self.sleep = sleep
        self.nutrition = nutrition
        self.energy = energy
        self.activities = activities
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

// MARK: - Activity Model
enum Activity: String, CaseIterable, Identifiable {
    case exercise = "Exercise"
    case social = "Social"
    case work = "Work"
    case relax = "Relax"
    case hobby = "Hobby"
    case family = "Family"
    case outdoor = "Outdoor"
    case creative = "Creative"
    case learning = "Learning"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case cooking = "Cooking"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .exercise: return "figure.run"
        case .social: return "person.2.fill"
        case .work: return "briefcase.fill"
        case .relax: return "leaf.fill"
        case .hobby: return "paintbrush.fill"
        case .family: return "house.fill"
        case .outdoor: return "tree.fill"
        case .creative: return "sparkles"
        case .learning: return "book.fill"
        case .shopping: return "cart.fill"
        case .entertainment: return "tv.fill"
        case .cooking: return "fork.knife"
        }
    }
    
    var color: Color {
        switch self {
        case .exercise: return .orange
        case .social: return .pink
        case .work: return .blue
        case .relax: return .green
        case .hobby: return .purple
        case .family: return .red
        case .outdoor: return .mint
        case .creative: return .yellow
        case .learning: return .indigo
        case .shopping: return .cyan
        case .entertainment: return .teal
        case .cooking: return .brown
        }
    }
}
