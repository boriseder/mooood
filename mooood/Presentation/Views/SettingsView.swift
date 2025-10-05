import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var biometricLockEnabled: Bool
    @Binding var reminderEnabled: Bool
    @Binding var reminderHour: Int
    @Binding var reminderMinute: Int
    
    let entries: [DailyEntry]
    
    @State private var showBackupSuccess = false
    @State private var showRestoreSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showFilePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Privacy Section
                Section {
                    Toggle("Require Authentication", isOn: $biometricLockEnabled)
                } header: {
                    Label("Privacy", systemImage: "lock.shield")
                } footer: {
                    Text("Use Face ID, Touch ID, or passcode to unlock the app")
                }
                
                // Notifications Section
                Section {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: Binding(
                                get: {
                                    Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? Date()
                                },
                                set: { newDate in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    reminderHour = components.hour ?? 20
                                    reminderMinute = components.minute ?? 0
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Label("Notifications", systemImage: "bell")
                } footer: {
                    if reminderEnabled {
                        Text("You'll receive a notification at this time each day")
                    }
                }
                
                // Backup & Restore Section
                Section {
                    Button {
                        exportBackup()
                    } label: {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Import Backup", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Label("Backup & Restore", systemImage: "externaldrive")
                } footer: {
                    Text("Export all your data as a backup file. You can restore it later on this or another device.")
                }
                
                // Stats Section
                Section {
                    HStack {
                        Text("Total Entries")
                        Spacer()
                        Text("\(entries.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Complete Entries")
                        Spacer()
                        Text("\(entries.filter { $0.isComplete }.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Current Streak")
                        Spacer()
                        Text("\(entries.calculateStreak()) days")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Statistics", systemImage: "chart.bar")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Backup Created", isPresented: $showBackupSuccess) {
                Button("OK") { }
            } message: {
                Text("Your backup has been saved successfully")
            }
            .alert("Restore Complete", isPresented: $showRestoreSuccess) {
                Button("OK") { }
            } message: {
                Text("Your data has been restored successfully")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }
    
    private func exportBackup() {
        let backup = BackupData(entries: entries.map { BackupEntry(from: $0) })
        
        guard let jsonData = try? JSONEncoder().encode(backup),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            errorMessage = "Failed to create backup"
            showError = true
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let filename = "mooood-backup-\(dateString).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try jsonString.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                activityVC.popoverPresentationController?.sourceView = topVC.view
                topVC.present(activityVC, animated: true) {
                    showBackupSuccess = true
                }
            }
        } catch {
            errorMessage = "Failed to save backup: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            let fileURL = try result.get().first
            guard let fileURL = fileURL else { return }
            
            guard fileURL.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file"
                showError = true
                return
            }
            
            defer { fileURL.stopAccessingSecurityScopedResource() }
            
            let jsonData = try Data(contentsOf: fileURL)
            let backup = try JSONDecoder().decode(BackupData.self, from: jsonData)
            
            // Clear existing data
            for entry in entries {
                modelContext.delete(entry)
            }
            
            // Import backup data
            for backupEntry in backup.entries {
                let entry = backupEntry.toDailyEntry()
                modelContext.insert(entry)
            }
            
            try modelContext.save()
            showRestoreSuccess = true
            
        } catch {
            errorMessage = "Failed to restore backup: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Backup Models
struct BackupData: Codable {
    let entries: [BackupEntry]
    var version: Int
    var exportDate: Date
    
    init(entries: [BackupEntry]) {
        self.entries = entries
        self.version = 1
        self.exportDate = Date()
    }
}

struct BackupEntry: Codable {
    let date: Date
    let mood: Int?
    let sleep: Int?
    let nutrition: Int?
    let energy: Int?
    let notes: String?
    let activities: [String]
    
    init(from entry: DailyEntry) {
        self.date = entry.date
        self.mood = entry.mood
        self.sleep = entry.sleep
        self.nutrition = entry.nutrition
        self.energy = entry.energy
        self.notes = entry.notes
        self.activities = entry.activities
    }
    
    func toDailyEntry() -> DailyEntry {
        DailyEntry(
            date: date,
            mood: mood,
            sleep: sleep,
            nutrition: nutrition,
            energy: energy,
            activities: activities,
            notes: notes
        )
    }
}
