//
//  InsightsView.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//


import SwiftUI
import SwiftData

struct InsightsView: View {
    let entries: [DailyEntry]
    
    var insights: [Insight] {
        generateInsights()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Insights", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            if insights.isEmpty {
                Text("Complete more entries to see personalized insights")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(insights) { insight in
                        insightCard(insight)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func insightCard(_ insight: Insight) -> some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: insight.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline.bold())
                
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func generateInsights() -> [Insight] {
        var insights: [Insight] = []
        
        let completeEntries = entries.filter { $0.isComplete }
        guard completeEntries.count >= 5 else { return insights }
        
        // Best day for energy
        if let bestEnergyDay = findBestDayFor(metric: \.energy) {
            insights.append(Insight(
                icon: "bolt.fill",
                title: "Peak Energy Day",
                message: "Your energy is highest on \(bestEnergyDay)s",
                gradient: [.orange, .yellow]
            ))
        }
        
        // Best day for mood
        if let bestMoodDay = findBestDayFor(metric: \.mood) {
            insights.append(Insight(
                icon: "face.smiling.fill",
                title: "Happiest Day",
                message: "You feel best on \(bestMoodDay)s",
                gradient: [.blue, .purple]
            ))
        }
        
        // Sleep correlation
        if let sleepInsight = analyzeSleepImpact() {
            insights.append(sleepInsight)
        }
        
        // Nutrition correlation
        if let nutritionInsight = analyzeNutritionImpact() {
            insights.append(nutritionInsight)
        }
        
        // Streak info
        let streak = calculateStreak()
        if streak >= 3 {
            insights.append(Insight(
                icon: "flame.fill",
                title: "\(streak) Day Streak!",
                message: "You're on a roll! Keep logging daily.",
                gradient: [.red, .orange]
            ))
        }
        
        // Recent trend
        if let trend = analyzeTrend() {
            insights.append(trend)
        }
        
        return insights
    }
    
    private func findBestDayFor(metric: KeyPath<DailyEntry, Int?>) -> String? {
        let completeEntries = entries.filter { $0.isComplete }
        guard completeEntries.count >= 7 else { return nil }
        
        let calendar = Calendar.current
        var dayScores: [Int: [Int]] = [:]
        
        for entry in completeEntries {
            let weekday = calendar.component(.weekday, from: entry.date)
            if let value = entry[keyPath: metric] {
                dayScores[weekday, default: []].append(value)
            }
        }
        
        let averages = dayScores.mapValues { values in
            Double(values.reduce(0, +)) / Double(values.count)
        }
        
        guard let bestDay = averages.max(by: { $0.value < $1.value })?.key else { return nil }
        
        let formatter = DateFormatter()
        formatter.weekdaySymbols = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return formatter.weekdaySymbols[bestDay - 1]
    }
    
    private func analyzeSleepImpact() -> Insight? {
        let completeEntries = entries.filter { $0.isComplete }
        guard completeEntries.count >= 7 else { return nil }
        
        let goodSleep = completeEntries.filter { ($0.sleep ?? 0) >= 4 }
        let poorSleep = completeEntries.filter { ($0.sleep ?? 0) <= 2 }
        
        guard !goodSleep.isEmpty && !poorSleep.isEmpty else { return nil }
        
        let goodSleepEnergy = goodSleep.map { $0.energy ?? 0 }.reduce(0, +) / goodSleep.count
        let poorSleepEnergy = poorSleep.map { $0.energy ?? 0 }.reduce(0, +) / poorSleep.count
        
        if goodSleepEnergy > poorSleepEnergy {
            let diff = ((Double(goodSleepEnergy) - Double(poorSleepEnergy)) / Double(poorSleepEnergy)) * 100
            return Insight(
                icon: "moon.stars.fill",
                title: "Sleep Matters",
                message: String(format: "Better sleep boosts energy by %.0f%%", diff),
                gradient: [.indigo, .blue]
            )
        }
        
        return nil
    }
    
    private func analyzeNutritionImpact() -> Insight? {
        let completeEntries = entries.filter { $0.isComplete }
        guard completeEntries.count >= 7 else { return nil }
        
        let goodNutrition = completeEntries.filter { ($0.nutrition ?? 0) >= 4 }
        let poorNutrition = completeEntries.filter { ($0.nutrition ?? 0) <= 2 }
        
        guard !goodNutrition.isEmpty && !poorNutrition.isEmpty else { return nil }
        
        let goodNutritionMood = goodNutrition.map { $0.mood ?? 0 }.reduce(0, +) / goodNutrition.count
        let poorNutritionMood = poorNutrition.map { $0.mood ?? 0 }.reduce(0, +) / poorNutrition.count
        
        if goodNutritionMood > poorNutritionMood {
            return Insight(
                icon: "fork.knife",
                title: "Nutrition Impact",
                message: "Healthy eating improves your mood",
                gradient: [.green, .mint]
            )
        }
        
        return nil
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let completeEntries = entries.filter { $0.isComplete }.sorted { $0.date > $1.date }
        
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
    
    private func analyzeTrend() -> Insight? {
        let completeEntries = entries.filter { $0.isComplete }.sorted { $0.date > $1.date }
        guard completeEntries.count >= 7 else { return nil }
        
        let recent = Array(completeEntries.prefix(3))
        let older = Array(completeEntries.suffix(3))
        
        let recentAvg = recent.map { $0.mood ?? 0 }.reduce(0, +) / recent.count
        let olderAvg = older.map { $0.mood ?? 0 }.reduce(0, +) / older.count
        
        if recentAvg > olderAvg + 1 {
            return Insight(
                icon: "arrow.up.right.circle.fill",
                title: "Trending Up",
                message: "Your mood is improving lately!",
                gradient: [.green, .mint]
            )
        } else if recentAvg < olderAvg - 1 {
            return Insight(
                icon: "arrow.down.right.circle.fill",
                title: "Trending Down",
                message: "Take care of yourself this week",
                gradient: [.orange, .red]
            )
        }
        
        return nil
    }
}

struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let gradient: [Color]
}