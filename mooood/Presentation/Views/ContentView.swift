import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]
    @State private var showHistory = false
    @State private var showCalendar = false
    @State private var showSettings = false
    @AppStorage("dailyReminderEnabled") private var reminderEnabled = false
    @AppStorage("dailyReminderHour") private var reminderHour = 20
    @AppStorage("dailyReminderMinute") private var reminderMinute = 0
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @State private var isUnlocked = false
    
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
        Group {
            if biometricLockEnabled && !isUnlocked {
                BiometricLockView(isUnlocked: $isUnlocked)
            } else {
                mainContent
            }
        }
        .onAppear {
            if !biometricLockEnabled {
                isUnlocked = true
            }
        }
        .onChange(of: biometricLockEnabled) { _, newValue in
            if !newValue {
                isUnlocked = true
            }
        }
    }
    
    var mainContent: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.accentColor.opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        StreakCard(streak: entries.calculateStreak())
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        WeeklySummaryCard(entries: entries)
                            .padding(.horizontal, 20)
                        
                        Text(Date.now.formatted(date: .complete, time: .omitted))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        modernCategoryCard(
                            title: "How do you feel?",
                            subtitle: "Select your overall mood",
                            icon: "face.smiling",
                            gradient: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]
                        ) {
                            emojiSection
                        }
                        
                        modernCategoryCard(
                            title: "Sleep Quality",
                            subtitle: "Rate how well you slept",
                            icon: "moon.stars.fill",
                            gradient: [Color.indigo.opacity(0.6), Color.blue.opacity(0.6)]
                        ) {
                            starSection(
                                value: todayEntry.sleep,
                                color: .purple,
                                onChange: { todayEntry.sleep = $0; saveEntry() }
                            )
                        }
                        
                        modernCategoryCard(
                            title: "Nutrition",
                            subtitle: "How healthy did you eat?",
                            icon: "fork.knife",
                            gradient: [Color.green.opacity(0.6), Color.mint.opacity(0.6)]
                        ) {
                            starSection(
                                value: todayEntry.nutrition,
                                color: .green,
                                onChange: { todayEntry.nutrition = $0; saveEntry() }
                            )
                        }
                        
                        modernCategoryCard(
                            title: "Energy Level",
                            subtitle: "Your overall energy today",
                            icon: "bolt.fill",
                            gradient: [Color.orange.opacity(0.6), Color.yellow.opacity(0.6)]
                        ) {
                            energySection
                        }
                        
                        ActivitiesSection(
                            selectedActivities: Binding(
                                get: { todayEntry.activities },
                                set: { todayEntry.activities = $0 }
                            ),
                            onSave: saveEntry
                        )
                        
                        notesCard
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Daily Check-in")
                            .font(.headline)
                        Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button {
                            showCalendar = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        Button {
                            showHistory = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(entries: entries)
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView(entries: entries)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    biometricLockEnabled: $biometricLockEnabled,
                    reminderEnabled: $reminderEnabled,
                    reminderHour: $reminderHour,
                    reminderMinute: $reminderMinute,
                    entries: entries
                )
            }
            .onAppear {
                requestNotificationPermissions()
                if reminderEnabled {
                    scheduleReminder()
                }
            }
            .onChange(of: reminderEnabled) { _, newValue in
                if newValue {
                    scheduleReminder()
                } else {
                    cancelReminder()
                }
            }
            .onChange(of: reminderHour) { _, _ in
                if reminderEnabled {
                    scheduleReminder()
                }
            }
            .onChange(of: reminderMinute) { _, _ in
                if reminderEnabled {
                    scheduleReminder()
                }
            }
        }
    }
    
    private var emojiSection: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        todayEntry.mood = value
                        saveEntry()
                    }
                } label: {
                    Text(MoodEmoji(rawValue: value)?.emoji ?? "")
                        .font(.system(size: 32))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(todayEntry.mood == value ?
                                      Color.white.opacity(0.9) :
                                      Color.white.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    todayEntry.mood == value ?
                                    Color.white : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(todayEntry.mood == value ? 1.05 : 1)
                        .shadow(
                            color: todayEntry.mood == value ?
                            Color.black.opacity(0.1) : .clear,
                            radius: 8, y: 4
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func starSection(value: Int?, color: Color, onChange: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onChange(star)
                    }
                } label: {
                    Image(systemName: value != nil && star <= value! ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundStyle(value != nil && star <= value! ? color : Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var energySection: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { level in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        todayEntry.energy = level
                        saveEntry()
                    }
                } label: {
                    Image(systemName: todayEntry.energy != nil && level <= todayEntry.energy! ? "bolt.fill" : "bolt")
                        .font(.system(size: 28))
                        .foregroundStyle(todayEntry.energy != nil && level <= todayEntry.energy! ?
                                       Color.orange : Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("What made today special?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: Binding(
                    get: { todayEntry.notes ?? "" },
                    set: { todayEntry.notes = $0.isEmpty ? nil : $0; saveEntry() }
                ))
                .frame(height: 120)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if todayEntry.notes?.isEmpty ?? true {
                    Text("Share your thoughts, achievements, or reflections...")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func modernCategoryCard<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        gradient: [Color],
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            content()
        }
        .padding(20)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: gradient.first!.opacity(0.3), radius: 12, y: 6)
    }
    
    private func saveEntry() {
        try? modelContext.save()
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if !granted {
                DispatchQueue.main.async {
                    reminderEnabled = false
                }
            }
        }
    }
    
    private func scheduleReminder() {
        cancelReminder()
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "How was your day? Take a moment to reflect."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }
}
