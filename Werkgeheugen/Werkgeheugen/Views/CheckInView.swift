//
//  CheckInView.swift
//  Werkgeheugen
//
//  Evening check-in: review day + plan tomorrow
//

import SwiftUI

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var gamificationEngine: GamificationEngine

    @StateObject private var suggestionEngine = SuggestionEngine()

    @State private var brainDumpText = ""
    @State private var tomorrowTask: WGTask?
    @State private var showCompletion = false
    @State private var step = 0 // 0: review, 1: tomorrow, 2: brain dump

    var todayCompleted: [WGTask] {
        taskStore.todayCompletedTasks
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(i <= step ? Color.purple : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top)

                    Spacer()

                    // Content based on step
                    switch step {
                    case 0:
                        ReviewStepView(completedTasks: todayCompleted)
                    case 1:
                        TomorrowStepView(
                            suggestion: suggestionEngine.tomorrowTopPick(from: taskStore.activeTasks),
                            selectedTask: $tomorrowTask
                        )
                    case 2:
                        BrainDumpStepView(text: $brainDumpText)
                    default:
                        EmptyView()
                    }

                    Spacer()

                    // Navigation buttons
                    HStack(spacing: 16) {
                        if step > 0 {
                            Button("Terug") {
                                withAnimation {
                                    step -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }

                        Button(step == 2 ? "Afronden" : "Volgende") {
                            if step == 2 {
                                finishCheckIn()
                            } else {
                                withAnimation {
                                    step += 1
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                    .padding(.bottom, 32)
                }
                .padding()

                // Completion overlay
                if showCompletion {
                    CheckInCompletionView {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Avond Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                suggestionEngine.generateSuggestions(from: taskStore.tasks)
            }
        }
    }

    private func finishCheckIn() {
        // Save brain dump if not empty
        let trimmed = brainDumpText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            // Split by newlines and create tasks
            let lines = trimmed.components(separatedBy: .newlines)
            for line in lines {
                let taskTitle = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !taskTitle.isEmpty {
                    taskStore.addTask(title: taskTitle)
                }
            }
        }

        // Award check-in points
        gamificationEngine.awardCheckInPoints()

        // Show completion
        withAnimation {
            showCompletion = true
        }
    }
}

// MARK: - Review Step
struct ReviewStepView: View {
    let completedTasks: [WGTask]

    var body: some View {
        VStack(spacing: 24) {
            // Mascot
            Text("🌙")
                .font(.system(size: 60))

            Text("Goed gedaan vandaag!")
                .font(.title2.weight(.bold))

            // Stats
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(completedTasks.count) taken afgerond")
                        .font(.headline)
                }

                if !completedTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(completedTasks.prefix(5)) { task in
                            HStack {
                                Text("✓")
                                    .foregroundStyle(.green)
                                Text(task.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                        }

                        if completedTasks.count > 5 {
                            Text("... en \(completedTasks.count - 5) meer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }

            if completedTasks.isEmpty {
                Text("Morgen is een nieuwe dag! 💪")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Tomorrow Step
struct TomorrowStepView: View {
    let suggestion: WGTask?
    @Binding var selectedTask: WGTask?

    var body: some View {
        VStack(spacing: 24) {
            Text("☀️")
                .font(.system(size: 60))

            Text("Top 1 voor morgen")
                .font(.title2.weight(.bold))

            if let task = suggestion {
                VStack(spacing: 12) {
                    Text("Suggestie:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        Text(task.category.icon)
                            .font(.title)

                        Text(task.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        Text(task.displayMicroStep)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purple.opacity(0.1))
                    )

                    Button {
                        selectedTask = task
                        HapticFeedback.medium()
                    } label: {
                        HStack {
                            Image(systemName: selectedTask == task ? "checkmark.circle.fill" : "circle")
                            Text("Dit wordt mijn focus")
                        }
                        .font(.subheadline.weight(.medium))
                    }
                }
            } else {
                Text("Alle taken zijn af! Geniet van je avond.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Brain Dump Step
struct BrainDumpStepView: View {
    @Binding var text: String

    var body: some View {
        VStack(spacing: 24) {
            Text("🧠")
                .font(.system(size: 60))

            Text("Brain Dump")
                .font(.title2.weight(.bold))

            Text("Nog iets op je hoofd? Dump het hier.\nElke regel wordt een taak.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextEditor(text: $text)
                .frame(height: 150)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                )

            Text("💡 Tip: Het hoeft niet perfect. Morgen kun je triagen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Completion View
struct CheckInCompletionView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("🌟")
                    .font(.system(size: 80))

                Text("Check-in voltooid!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                Text(MascotMessages.randomEvening())
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Button {
                    onDismiss()
                } label: {
                    Text("Welterusten!")
                        .font(.headline)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(.white)
                        )
                }
                .padding(.top)
            }
        }
    }
}

#Preview {
    CheckInView()
        .environmentObject(TaskStore())
        .environmentObject(GamificationEngine())
}
