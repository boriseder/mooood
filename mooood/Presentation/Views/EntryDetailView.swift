import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var entry: DailyEntry
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Date Header
                        VStack(spacing: 4) {
                            Text(entry.date.formatted(date: .complete, time: .omitted))
                                .font(.title2.bold())
                            
                            Text(entry.date.formatted(.relative(presentation: .named)))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                        
                        // Mood
                        editCategoryCard(
                            title: "How did you feel?",
                            subtitle: "Select your overall mood",
                            icon: "face.smiling",
                            gradient: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]
                        ) {
                            emojiSection
                        }
                        
                        // Sleep
                        editCategoryCard(
                            title: "Sleep Quality",
                            subtitle: "Rate how well you slept",
                            icon: "moon.stars.fill",
                            gradient: [Color.indigo.opacity(0.6), Color.blue.opacity(0.6)]
                        ) {
                            starSection(
                                value: entry.sleep,
                                color: .purple,
                                onChange: { entry.sleep = $0; saveEntry() }
                            )
                        }
                        
                        // Nutrition
                        editCategoryCard(
                            title: "Nutrition",
                            subtitle: "How healthy did you eat?",
                            icon: "fork.knife",
                            gradient: [Color.green.opacity(0.6), Color.mint.opacity(0.6)]
                        ) {
                            starSection(
                                value: entry.nutrition,
                                color: .green,
                                onChange: { entry.nutrition = $0; saveEntry() }
                            )
                        }
                        
                        // Energy
                        editCategoryCard(
                            title: "Energy Level",
                            subtitle: "Your overall energy today",
                            icon: "bolt.fill",
                            gradient: [Color.orange.opacity(0.6), Color.yellow.opacity(0.6)]
                        ) {
                            energySection
                        }
                        
                        // Activities
                        ActivitiesSection(
                            selectedActivities: Binding(
                                get: { entry.activities },
                                set: { entry.activities = $0 }
                            ),
                            onSave: saveEntry
                        )
                        
                        // Notes
                        notesCard
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.medium))
                }
            }
        }
    }
    
    private var emojiSection: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        entry.mood = value
                        saveEntry()
                    }
                } label: {
                    Text(MoodEmoji(rawValue: value)?.emoji ?? "")
                        .font(.system(size: 32))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(entry.mood == value ?
                                      Color.white.opacity(0.9) :
                                      Color.white.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    entry.mood == value ?
                                    Color.white : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(entry.mood == value ? 1.05 : 1)
                        .shadow(
                            color: entry.mood == value ?
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
                        entry.energy = level
                        saveEntry()
                    }
                } label: {
                    Image(systemName: entry.energy != nil && level <= entry.energy! ? "bolt.fill" : "bolt")
                        .font(.system(size: 28))
                        .foregroundStyle(entry.energy != nil && level <= entry.energy! ?
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
            
            TextEditor(text: Binding(
                get: { entry.notes ?? "" },
                set: { entry.notes = $0.isEmpty ? nil : $0; saveEntry() }
            ))
            .frame(height: 120)
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func editCategoryCard<Content: View>(
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
}
