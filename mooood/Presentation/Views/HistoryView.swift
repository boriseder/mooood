import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    let entries: [DailyEntry]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showExportSheet = false
    @State private var selectedCategory: Category = .mood
    @State private var selectedEntry: DailyEntry?
    
    enum Category: String, CaseIterable {
        case mood = "Mood"
        case sleep = "Sleep"
        case nutrition = "Nutrition"
        case energy = "Energy"
        
        var gradient: [Color] {
            switch self {
            case .mood: return [.blue, .purple]
            case .sleep: return [.indigo, .blue]
            case .nutrition: return [.green, .mint]
            case .energy: return [.orange, .yellow]
            }
        }
        
        var icon: String {
            switch self {
            case .mood: return "face.smiling"
            case .sleep: return "moon.stars.fill"
            case .nutrition: return "fork.knife"
            case .energy: return "bolt.fill"
            }
        }
    }
    
    var completeEntries: [DailyEntry] {
        entries.filter { $0.isComplete }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        selectedCategory.gradient.first!.opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    if !completeEntries.isEmpty {
                        VStack(spacing: 24) {
                            categoryPicker
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            chartCard
                                .padding(.horizontal, 20)
                            
                            statsGrid
                                .padding(.horizontal, 20)
                            
                            // Insights
                            InsightsView(entries: completeEntries)
                                .padding(.horizontal, 20)
                            
                            entriesList
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary.opacity(0.5))
                            
                            Text("No Complete Entries Yet")
                                .font(.title2.bold())
                            
                            Text("Complete all categories to see your history and trends")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("History & Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.medium))
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
            .sheet(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }
    
    private var categoryPicker: some View {
        HStack(spacing: 12) {
            ForEach(Category.allCases, id: \.self) { category in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .font(.system(size: 14))
                        
                        if selectedCategory == category {
                            Text(category.rawValue)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                    .padding(.horizontal, selectedCategory == category ? 16 : 12)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            if selectedCategory == category {
                                LinearGradient(
                                    colors: category.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color(.systemGray6)
                            }
                        }
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Trend Analysis", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                
                Spacer()
                
                Text("\(completeEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(completeEntries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Value", valueForCategory(entry))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: selectedCategory.gradient,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Value", valueForCategory(entry))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: selectedCategory.gradient.map { $0.opacity(0.2) },
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Value", valueForCategory(entry))
                    )
                    .foregroundStyle(selectedCategory.gradient.first!)
                    .symbolSize(80)
                }
            }
            .frame(height: 220)
            .chartYScale(domain: 1...5)
            .chartYAxis {
                AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: selectedCategory.gradient.first!.opacity(0.2), radius: 12, y: 6)
    }
    
    private var statsGrid: some View {
        HStack(spacing: 12) {
            modernStatCard(
                title: "Average",
                value: String(format: "%.1f", averageForCategory()),
                icon: "chart.bar.fill",
                gradient: [.blue.opacity(0.6), .cyan.opacity(0.6)]
            )
            
            modernStatCard(
                title: "Highest",
                value: "\(maxForCategory())",
                icon: "arrow.up.circle.fill",
                gradient: [.green.opacity(0.6), .mint.opacity(0.6)]
            )
            
            modernStatCard(
                title: "Lowest",
                value: "\(minForCategory())",
                icon: "arrow.down.circle.fill",
                gradient: [.orange.opacity(0.6), .pink.opacity(0.6)]
            )
        }
    }
    
    private func modernStatCard(title: String, value: String, icon: String, gradient: [Color]) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.white)
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var entriesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.headline)
                .padding(.horizontal, 4)
            
            List {
                ForEach(completeEntries.prefix(10)) { entry in
                    modernEntryRow(entry: entry)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteEntry(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    
                    if entry.id != completeEntries.prefix(10).last?.id {
                        Divider()
                            .padding(.leading, 60)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(height: CGFloat(completeEntries.prefix(10).count) * 80)
        }
    }
    
    private func modernEntryRow(entry: DailyEntry) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(entry.date.formatted(.dateTime.day()))
                    .font(.title3.bold())
                Text(entry.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    metricBadge(icon: "face.smiling", value: entry.mood ?? 0, color: .blue)
                    metricBadge(icon: "moon.stars.fill", value: entry.sleep ?? 0, color: .purple)
                    metricBadge(icon: "fork.knife", value: entry.nutrition ?? 0, color: .green)
                    metricBadge(icon: "bolt.fill", value: entry.energy ?? 0, color: .orange)
                }
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .contentShape(Rectangle())
    }
    
    private func metricBadge(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text("\(value)")
                .font(.caption.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
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
    
    private func deleteEntry(_ entry: DailyEntry) {
        withAnimation {
            modelContext.delete(entry)
            try? modelContext.save()
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
