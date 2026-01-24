//
//  SettingsView.swift
//  Werkgeheugen
//
//  App settings: notifications, export, preferences
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var notificationService: NotificationService

    @Query private var settings: [UserSettings]

    @State private var showExportSheet = false
    @State private var exportFormat: ExportFormat = .json
    @State private var exportContent = ""
    @State private var showAbout = false

    var currentSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    var body: some View {
        NavigationStack {
            Form {
                // Notifications section
                Section {
                    Toggle("Notificaties aan", isOn: Binding(
                        get: { currentSettings.notificationsEnabled },
                        set: { newValue in
                            currentSettings.notificationsEnabled = newValue
                            saveSettings()
                        }
                    ))

                    if currentSettings.notificationsEnabled {
                        NotificationTimeRow(
                            label: "Ochtend",
                            time: currentSettings.morningNotificationTime,
                            enabled: currentSettings.morningEnabled,
                            onTimeChange: { minutes in
                                currentSettings.morningNotificationTime = minutes
                                saveSettings()
                            },
                            onToggle: { enabled in
                                currentSettings.morningEnabled = enabled
                                saveSettings()
                            }
                        )

                        NotificationTimeRow(
                            label: "Middag",
                            time: currentSettings.middayNotificationTime,
                            enabled: currentSettings.middayEnabled,
                            onTimeChange: { minutes in
                                currentSettings.middayNotificationTime = minutes
                                saveSettings()
                            },
                            onToggle: { enabled in
                                currentSettings.middayEnabled = enabled
                                saveSettings()
                            }
                        )

                        NotificationTimeRow(
                            label: "Avond",
                            time: currentSettings.eveningNotificationTime,
                            enabled: currentSettings.eveningEnabled,
                            onTimeChange: { minutes in
                                currentSettings.eveningNotificationTime = minutes
                                saveSettings()
                            },
                            onToggle: { enabled in
                                currentSettings.eveningEnabled = enabled
                                saveSettings()
                            }
                        )

                        Picker("Toon", selection: Binding(
                            get: { currentSettings.strictness },
                            set: { newValue in
                                currentSettings.strictness = newValue
                                saveSettings()
                            }
                        )) {
                            ForEach(NotificationStrictness.allCases, id: \.rawValue) { strictness in
                                Text(strictness.label)
                                    .tag(strictness)
                            }
                        }
                    }
                } header: {
                    Text("Notificaties")
                } footer: {
                    Text("De avond check-in helpt je de dag af te sluiten en morgen te plannen.")
                }

                // Experience section
                Section {
                    Toggle("Haptics", isOn: Binding(
                        get: { currentSettings.hapticsEnabled },
                        set: { newValue in
                            currentSettings.hapticsEnabled = newValue
                            saveSettings()
                        }
                    ))

                    Toggle("Confetti", isOn: Binding(
                        get: { currentSettings.confettiEnabled },
                        set: { newValue in
                            currentSettings.confettiEnabled = newValue
                            saveSettings()
                        }
                    ))

                    Toggle("Mascotte", isOn: Binding(
                        get: { currentSettings.mascotEnabled },
                        set: { newValue in
                            currentSettings.mascotEnabled = newValue
                            saveSettings()
                        }
                    ))
                } header: {
                    Text("Beleving")
                }

                // Export section
                Section {
                    Button {
                        exportFormat = .json
                        exportContent = taskStore.exportToJSON()
                        showExportSheet = true
                    } label: {
                        Label("Exporteer als JSON", systemImage: "doc.text")
                    }

                    Button {
                        exportFormat = .csv
                        exportContent = taskStore.exportToCSV()
                        showExportSheet = true
                    } label: {
                        Label("Exporteer als CSV", systemImage: "tablecells")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Je data blijft altijd lokaal op je device. Exporteer om een backup te maken.")
                }

                // About section
                Section {
                    Button {
                        showAbout = true
                    } label: {
                        Label("Over Werkgeheugen", systemImage: "info.circle")
                    }

                    HStack {
                        Text("Versie")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Over")
                }

                // Debug section (only in development)
                #if DEBUG
                Section {
                    Button("Voeg test taken toe") {
                        addTestTasks()
                    }

                    Button("Reset alle data", role: .destructive) {
                        resetAllData()
                    }
                } header: {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle("Instellingen")
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(format: exportFormat, content: exportContent)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .onAppear {
                ensureSettingsExist()
            }
        }
    }

    private func ensureSettingsExist() {
        if settings.isEmpty {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }

    private func saveSettings() {
        currentSettings.updatedAt = Date()
        try? modelContext.save()

        // Reschedule notifications
        notificationService.scheduleAllNotifications(settings: currentSettings)
    }

    #if DEBUG
    private func addTestTasks() {
        let testTasks = [
            ("Mail accountant beantwoorden", TaskCategory.werk, "Open mail van accountant"),
            ("Belastingaangifte voorbereiden", TaskCategory.financien, "Zoek jaarcijfers"),
            ("Teamtraining plannen", TaskCategory.voetbal, "Check teamapp voor beschikbaarheid"),
            ("App feature bouwen", TaskCategory.apps, "Open Xcode project"),
            ("Boodschappen doen", TaskCategory.gezin, "Maak boodschappenlijst")
        ]

        for (title, category, microStep) in testTasks {
            taskStore.addTask(
                title: title,
                category: category,
                priority: [TaskPriority.p1, .p2, .p3].randomElement()!,
                effort: TaskEffort.allCases.randomElement()!,
                microStep: microStep
            )
        }
    }

    private func resetAllData() {
        // Delete all tasks
        for task in taskStore.tasks {
            modelContext.delete(task)
        }
        try? modelContext.save()
        taskStore.fetchTasks()
    }
    #endif
}

// MARK: - Notification Time Row
struct NotificationTimeRow: View {
    let label: String
    let time: Int
    let enabled: Bool
    let onTimeChange: (Int) -> Void
    let onToggle: (Bool) -> Void

    @State private var showTimePicker = false

    var body: some View {
        HStack {
            Toggle(label, isOn: Binding(
                get: { enabled },
                set: { onToggle($0) }
            ))

            if enabled {
                Spacer()

                Button {
                    showTimePicker = true
                } label: {
                    Text(formattedTime)
                        .foregroundStyle(.purple)
                }
                .sheet(isPresented: $showTimePicker) {
                    TimePickerSheet(
                        title: "\(label) notificatie",
                        initialMinutes: time,
                        onSave: onTimeChange
                    )
                }
            }
        }
    }

    var formattedTime: String {
        let hours = time / 60
        let minutes = time % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

// MARK: - Time Picker Sheet
struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let initialMinutes: Int
    let onSave: (Int) -> Void

    @State private var selectedTime: Date

    init(title: String, initialMinutes: Int, onSave: @escaping (Int) -> Void) {
        self.title = title
        self.initialMinutes = initialMinutes
        self.onSave = onSave

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        self._selectedTime = State(
            initialValue: calendar.date(byAdding: .minute, value: initialMinutes, to: today) ?? today
        )
    }

    var body: some View {
        NavigationStack {
            DatePicker(
                "Tijd",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Opslaan") {
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
                        let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                        onSave(minutes)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Export Sheet
struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let format: ExportFormat
    let content: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Je data in \(format.rawValue.uppercased()) formaat:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(content)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemBackground))
                        )

                    ShareLink(
                        item: content,
                        subject: Text("Werkgeheugen Export"),
                        message: Text("Mijn taken export")
                    ) {
                        Label("Deel", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                .padding()
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Klaar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum ExportFormat: String {
    case json
    case csv
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Text("🧠")
                            .font(.system(size: 50))
                    }
                    .padding(.top, 32)

                    Text("Werkgeheugen")
                        .font(.title.weight(.bold))

                    Text("ADHD-vriendelijke taak app")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider()
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "bolt.fill",
                            title: "Supersnelle capture",
                            description: "Tekst of voice, direct opslaan"
                        )

                        FeatureRow(
                            icon: "1.circle.fill",
                            title: "Microstappen",
                            description: "Focus op de allereerste kleine actie"
                        )

                        FeatureRow(
                            icon: "star.fill",
                            title: "Gamification",
                            description: "Punten, badges en streaks"
                        )

                        FeatureRow(
                            icon: "lock.fill",
                            title: "Privacy first",
                            description: "Alle data lokaal, geen tracking"
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Text("Gebouwd met ❤️ voor iedereen\ndie worstelt met to-do lijsten")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 32)
                }
            }
            .navigationTitle("Over")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Klaar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TaskStore())
        .environmentObject(NotificationService())
}
