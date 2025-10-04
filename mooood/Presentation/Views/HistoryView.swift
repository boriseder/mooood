//
//  HistoryView.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//
import SwiftUI
import SwiftData
import Charts

// MARK: - History View
struct HistoryView: View {
    let entries: [DailyEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var showExportSheet = false
    @State private var selectedCategory: Category = .mood
    
    enum Category: String, CaseIterable {
        case mood = "Mood"
        case sleep = "Sleep"
        case nutrition = "Nutrition"
        case energy = "Energy"
        
        var color: Color {
            switch self {
            case .mood: return .blue
            case .sleep: return .purple
            case .nutrition: return .green
            case .energy: return .orange
            }
        }
    }
    
    var completeEntries: [DailyEntry] {
        entries.filter { $0.isComplete }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !completeEntries.isEmpty {
                        // Category picker
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Chart
                        chartView
                            .frame(height: 250)
                            .padding()
                        
                        // Statistics
                        statsView
                            .padding(.horizontal)
                        
                        // List of entries
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(completeEntries) { entry in
                                EntryRow(entry: entry)
                                
                                if entry != completeEntries.last {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    } else {
                        ContentUnavailableView(
                            "No Complete Entries",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("Complete all categories to see history")
                        )
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(completeEntries.isEmpty)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(items: [generateCSV()])
            }
        }
    }
    
    private var chartView: some View {
        Chart {
            ForEach(completeEntries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Value", valueForCategory(entry))
                )
                .foregroundStyle(selectedCategory.color)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Value", valueForCategory(entry))
                )
                .foregroundStyle(selectedCategory.color)
                .symbolSize(60)
            }
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5])
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
    
    private var statsView: some View {
        HStack(spacing: 20) {
            StatCard(title: "Average", value: String(format: "%.1f", averageForCategory()))
            StatCard(title: "Highest", value: "\(maxForCategory())")
            StatCard(title: "Lowest", value: "\(minForCategory())")
        }
    }
    
    private func valueForCategory(_ entry: DailyEntry) -> Int {
        switch selectedCategory {
        case .mood: return entry.mood ?? 0
        case .sleep: return entry.sleep ?? 0
        case .nutrition: return entry.nutrition ?? 0
        case .energy: return entry.energy ?? 0
        }
    }
    
    private func averageForCategory() -> Double {
        let values = completeEntries.map { valueForCategory($0) }
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0, +)) / Double(values.count)
    }
    
    private func maxForCategory() -> Int {
        completeEntries.map { valueForCategory($0) }.max() ?? 0
    }
    
    private func minForCategory() -> Int {
        completeEntries.map { valueForCategory($0) }.min() ?? 0
    }
    
    private func generateCSV() -> URL {
        var csv = "Date,Mood,Sleep,Nutrition,Energy,Notes\n"

        for entry in completeEntries.reversed() {
            let dateString = entry.date.formatted(date: .numeric, time: .omitted)
            
            csv += "\(dateString),\(entry.mood ?? 0),\(entry.sleep ?? 0),\(entry.nutrition ?? 0),\(entry.energy ?? 0),\"\(entry.notes ?? "")\"\n"
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("daily_tracker_data.csv")
        
        
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        
        return tempURL
    }
}
