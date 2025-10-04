import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let entries: [DailyEntry]
    
    @State private var currentMonth = Date()
    @State private var selectedDate: Date?
    @State private var showEntryDetail = false
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color.blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Month Navigation
                    monthHeader
                    
                    // Calendar Grid
                    calendarGrid
                    
                    // Legend
                    legendView
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        withAnimation {
                            currentMonth = Date()
                        }
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
            .sheet(item: $selectedDate) { date in
                if let entry = getEntry(for: date) {
                    EntryDetailView(entry: entry)
                } else {
                    createEntryView(for: date)
                }
            }
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title2.bold())
            
            Spacer()
            
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
    }
    
    private var calendarGrid: some View {
        VStack(spacing: 12) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<daysInMonth().count, id: \.self) { index in
                    let date = daysInMonth()[index]
                    if let date = date {
                        DayCell(
                            date: date,
                            entry: getEntry(for: date),
                            isToday: calendar.isDateInToday(date),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var legendView: some View {
        HStack(spacing: 20) {
            LegendItem(color: .gray.opacity(0.3), label: "No entry")
            LegendItem(color: .blue, label: "Incomplete")
            LegendItem(color: .green, label: "Complete")
        }
        .font(.caption)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var date = monthFirstWeek.start
        
        while days.count < 42 { // 6 weeks
            if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                days.append(date)
            } else {
                days.append(nil)
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return days
    }
    
    private func getEntry(for date: Date) -> DailyEntry? {
        entries.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func createEntryView(for date: Date) -> some View {
        let entry = DailyEntry(date: date)
        modelContext.insert(entry)
        return EntryDetailView(entry: entry)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let entry: DailyEntry?
    let isToday: Bool
    let isCurrentMonth: Bool
    
    var cellColor: Color {
        if entry?.isComplete == true {
            return .green
        } else if entry != nil {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    var moodGradient: [Color]? {
        guard let mood = entry?.mood else { return nil }
        switch mood {
        case 1: return [.red.opacity(0.6), .red.opacity(0.3)]
        case 2: return [.orange.opacity(0.6), .orange.opacity(0.3)]
        case 3: return [.yellow.opacity(0.6), .yellow.opacity(0.3)]
        case 4: return [.green.opacity(0.6), .green.opacity(0.3)]
        case 5: return [.blue.opacity(0.6), .blue.opacity(0.3)]
        default: return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.body.weight(isToday ? .bold : .regular))
                .foregroundStyle(isCurrentMonth ? .primary : .secondary)
            
            if let gradient = moodGradient {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(cellColor)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isToday ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .opacity(isCurrentMonth ? 1 : 0.3)
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Date Extension for Sheet

extension Date: Identifiable {
    public var id: TimeInterval {
        self.timeIntervalSince1970
    }
}
