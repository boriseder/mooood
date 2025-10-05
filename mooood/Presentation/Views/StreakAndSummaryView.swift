//
//  StreakCard.swift
//  mooood
//
//  Created by Boris Eder on 05.10.25.
//


import SwiftUI
import SwiftData

// MARK: - Streak Card
struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Text("🔥")
                    .font(.system(size: 32))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(streak)")
                        .font(.title.bold())
                    Text("Day Streak")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Text(streakMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var streakMessage: String {
        switch streak {
        case 0: return "Start your journey today!"
        case 1: return "Great start! Keep it going"
        case 2...6: return "You're building a habit!"
        case 7...13: return "One week down! Amazing!"
        case 14...29: return "Two weeks strong! 💪"
        case 30...: return "Incredible dedication! 🌟"
        default: return ""
        }
    }
}

// MARK: - Weekly Summary Card
struct WeeklySummaryCard: View {
    let entries: [DailyEntry]
    
    private var weekData: WeekData {
        calculateWeekData()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("This Week", systemImage: "calendar.badge.clock")
                    .font(.headline)
                
                Spacer()
                
                if weekData.trend != .stable {
                    HStack(spacing: 4) {
                        Image(systemName: weekData.trend == .up ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.bold())
                        Text(weekData.trend == .up ? "Improving" : "Declining")
                            .font(.caption)
                    }
                    .foregroundStyle(weekData.trend == .up ? .green : .orange)
                }
            }
            
            HStack(spacing: 12) {
                SummaryMetric(
                    icon: "face.smiling",
                    value: weekData.avgMood,
                    label: "Avg Mood",
                    color: .blue
                )
                
                SummaryMetric(
                    icon: "moon.stars.fill",
                    value: weekData.avgSleep,
                    label: "Avg Sleep",
                    color: .purple
                )
                
                SummaryMetric(
                    icon: "bolt.fill",
                    value: weekData.avgEnergy,
                    label: "Avg Energy",
                    color: .orange
                )
            }
            
            if !weekData.topActivities.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Top Activities")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(weekData.topActivities.prefix(3), id: \.self) { activityName in
                            if let activity = Activity.allCases.first(where: { $0.rawValue == activityName }) {
                                HStack(spacing: 4) {
                                    Image(systemName: activity.icon)
                                        .font(.caption2)
                                    Text(activity.rawValue)
                                        .font(.caption2)
                                }
                                .foregroundStyle(activity.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(activity.color.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func calculateWeekData() -> WeekData {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let thisWeekEntries = entries.filter {
            $0.isComplete && $0.date >= weekAgo
        }
        
        guard !thisWeekEntries.isEmpty else {
            return WeekData(avgMood: 0, avgSleep: 0, avgEnergy: 0, trend: .stable, topActivities: [])
        }
        
        let avgMood = Double(thisWeekEntries.compactMap { $0.mood }.reduce(0, +)) / Double(thisWeekEntries.count)
        let avgSleep = Double(thisWeekEntries.compactMap { $0.sleep }.reduce(0, +)) / Double(thisWeekEntries.count)
        let avgEnergy = Double(thisWeekEntries.compactMap { $0.energy }.reduce(0, +)) / Double(thisWeekEntries.count)
        
        // Calculate trend
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
        let lastWeekEntries = entries.filter {
            $0.isComplete && $0.date >= twoWeeksAgo && $0.date < weekAgo
        }
        
        var trend: Trend = .stable
        if !lastWeekEntries.isEmpty {
            let lastWeekAvgMood = Double(lastWeekEntries.compactMap { $0.mood }.reduce(0, +)) / Double(lastWeekEntries.count)
            if avgMood > lastWeekAvgMood + 0.5 {
                trend = .up
            } else if avgMood < lastWeekAvgMood - 0.5 {
                trend = .down
            }
        }
        
        // Top activities
        var activityCounts: [String: Int] = [:]
        for entry in thisWeekEntries {
            for activity in entry.activities {
                activityCounts[activity, default: 0] += 1
            }
        }
        let topActivities = activityCounts.sorted { $0.value > $1.value }.map { $0.key }
        
        return WeekData(
            avgMood: avgMood,
            avgSleep: avgSleep,
            avgEnergy: avgEnergy,
            trend: trend,
            topActivities: topActivities
        )
    }
}

// MARK: - Summary Metric
struct SummaryMetric: View {
    let icon: String
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(String(format: "%.1f", value))
                .font(.title3.bold())
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Supporting Types
struct WeekData {
    let avgMood: Double
    let avgSleep: Double
    let avgEnergy: Double
    let trend: Trend
    let topActivities: [String]
}

enum Trend {
    case up, down, stable
}

// MARK: - Streak Calculator
extension Array where Element == DailyEntry {
    func calculateStreak() -> Int {
        let calendar = Calendar.current
        let completeEntries = self.filter { $0.isComplete }.sorted { $0.date > $1.date }
        
        guard !completeEntries.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for entry in completeEntries {
            let entryDate = calendar.startOfDay(for: entry.date)
            
            if calendar.isDate(entryDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if entryDate < currentDate {
                break
            }
        }
        
        return streak
    }
}