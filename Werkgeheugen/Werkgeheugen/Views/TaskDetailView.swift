//
//  TaskDetailView.swift
//  Werkgeheugen
//
//  Full task editing view
//

import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskStore: TaskStore

    @Bindable var task: WGTask

    @State private var showDeleteConfirmation = false
    @StateObject private var audioService = AudioService()

    var body: some View {
        NavigationStack {
            Form {
                // Title section
                Section {
                    TextField("Taak titel", text: $task.title)
                        .font(.headline)
                } header: {
                    Text("Titel")
                }

                // Microstep section
                Section {
                    TextField("Eerste kleine stap...", text: $task.microStep)

                    if task.microStep.isEmpty {
                        Text("💡 Tip: \"\(task.category.defaultMicroAction)\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Microstap")
                } footer: {
                    Text("Wat is de allereerste, kleinste actie?")
                }

                // Category & Priority
                Section {
                    Picker("Categorie", selection: $task.category) {
                        ForEach(TaskCategory.allCases) { category in
                            Text("\(category.icon) \(category.label)")
                                .tag(category)
                        }
                    }

                    Picker("Prioriteit", selection: $task.priority) {
                        ForEach(TaskPriority.allCases, id: \.rawValue) { priority in
                            Text(priority.label)
                                .tag(priority)
                        }
                    }

                    Toggle("Urgent", isOn: $task.isUrgent)
                }

                // Effort & Due date
                Section {
                    Picker("Inspanning", selection: $task.effort) {
                        ForEach(TaskEffort.allCases, id: \.rawValue) { effort in
                            Text(effort.label)
                                .tag(effort)
                        }
                    }

                    Toggle("Deadline", isOn: Binding(
                        get: { task.dueDate != nil },
                        set: { hasDate in
                            if hasDate {
                                task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                            } else {
                                task.dueDate = nil
                            }
                        }
                    ))

                    if let dueDate = task.dueDate {
                        DatePicker(
                            "Datum",
                            selection: Binding(
                                get: { dueDate },
                                set: { task.dueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                // Notes
                Section {
                    TextField("Notities...", text: $task.notes, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Notities")
                }

                // Audio attachment
                if let audioPath = task.audioFilePath, audioService.audioFileExists(at: audioPath) {
                    Section {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundStyle(.purple)

                            Text("Voice opname")

                            Spacer()

                            Button("Afspelen") {
                                audioService.playAudio(at: URL(fileURLWithPath: audioPath))
                            }
                            .buttonStyle(.bordered)
                        }
                    } header: {
                        Text("Bijlage")
                    }
                }

                // Status
                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(task.status.label)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Aangemaakt")
                        Spacer()
                        Text(task.createdAt, style: .relative)
                            .foregroundStyle(.secondary)
                    }

                    if let completedAt = task.completedAt {
                        HStack {
                            Text("Afgerond")
                            Spacer()
                            Text(completedAt, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if task.pointsEarned > 0 {
                        HStack {
                            Text("Punten verdiend")
                            Spacer()
                            Text("+\(task.pointsEarned)")
                                .foregroundStyle(.yellow)
                        }
                    }
                } header: {
                    Text("Info")
                }

                // Delete button
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Verwijder taak", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Taak bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Klaar") {
                        saveAndDismiss()
                    }
                }
            }
            .confirmationDialog("Weet je het zeker?", isPresented: $showDeleteConfirmation) {
                Button("Verwijder", role: .destructive) {
                    taskStore.deleteTask(task)
                    dismiss()
                }
                Button("Annuleren", role: .cancel) { }
            } message: {
                Text("Deze taak wordt permanent verwijderd.")
            }
        }
    }

    private func saveAndDismiss() {
        taskStore.updateTask(task)
        dismiss()
    }
}

#Preview {
    TaskDetailView(task: WGTask(title: "Test taak"))
        .environmentObject(TaskStore())
}
