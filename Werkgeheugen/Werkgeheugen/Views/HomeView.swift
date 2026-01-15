//
//  HomeView.swift
//  Werkgeheugen
//
//  "Nu" view - Today's microsteps + Quick Add + Voice
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var gamificationEngine: GamificationEngine

    @StateObject private var suggestionEngine = SuggestionEngine()
    @StateObject private var audioService = AudioService()
    @StateObject private var speechService = SpeechService()

    @State private var showQuickAdd = false
    @State private var quickAddText = ""
    @State private var isRecordingVoice = false
    @State private var showFocusMode = false
    @State private var focusTask: WGTask?
    @State private var recordedAudioURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with mascot
                    MascotHeaderView()

                    // Quick Add Section
                    QuickAddCard(
                        text: $quickAddText,
                        isRecording: $isRecordingVoice,
                        onAdd: addQuickTask,
                        onVoiceStart: startVoiceRecording,
                        onVoiceStop: stopVoiceRecording,
                        audioLevel: audioService.audioLevel
                    )

                    // Today's Focus (max 3 microsteps)
                    TodaysFocusSection(
                        tasks: suggestionEngine.todaysFocus(from: taskStore.activeTasks),
                        onTap: { task in
                            focusTask = task
                            showFocusMode = true
                        },
                        onComplete: completeTask
                    )

                    // Suggestions Section
                    SuggestionsSection(
                        suggestions: suggestionEngine.dailySuggestions,
                        quickWin: suggestionEngine.quickWin,
                        onSelect: { suggestion in
                            if let task = suggestion.task {
                                focusTask = task
                                showFocusMode = true
                            }
                        }
                    )

                    // Stats preview
                    QuickStatsCard()
                }
                .padding()
            }
            .navigationTitle("Nu")
            .background(Color(.systemGroupedBackground))
            .refreshable {
                refreshData()
            }
            .fullScreenCover(isPresented: $showFocusMode) {
                if let task = focusTask {
                    FocusModeView(task: task) {
                        showFocusMode = false
                        refreshData()
                    }
                }
            }
            .onAppear {
                refreshData()
            }
        }
    }

    // MARK: - Actions

    private func refreshData() {
        taskStore.fetchTasks()
        suggestionEngine.generateSuggestions(from: taskStore.tasks)
    }

    private func addQuickTask() {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        taskStore.addTask(title: trimmed)
        quickAddText = ""
        HapticFeedback.medium()
    }

    private func startVoiceRecording() {
        if !audioService.hasPermission {
            audioService.requestPermission()
            return
        }

        if !speechService.hasPermission {
            speechService.requestPermission { _ in }
            return
        }

        recordedAudioURL = audioService.startRecording()
        isRecordingVoice = true
        gamificationEngine.awardVoiceCapturePoints()
    }

    private func stopVoiceRecording() {
        guard let audioURL = audioService.stopRecording() else {
            isRecordingVoice = false
            return
        }

        isRecordingVoice = false

        // Transcribe the audio
        speechService.transcribeAudioFile(at: audioURL) { text in
            if let transcribedText = text, !transcribedText.isEmpty {
                taskStore.addTask(
                    title: transcribedText,
                    audioFilePath: audioURL.path
                )
                HapticFeedback.success()
            }
        }
    }

    private func completeTask(_ task: WGTask) {
        _ = taskStore.completeTask(task)
        gamificationEngine.awardTaskCompletionPoints()
        refreshData()
    }
}

// MARK: - Mascot Header
struct MascotHeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            // Simple blob mascot
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                // Eyes
                HStack(spacing: 8) {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                }
                .offset(y: -4)

                // Smile
                Path { path in
                    path.move(to: CGPoint(x: 18, y: 30))
                    path.addQuadCurve(
                        to: CGPoint(x: 32, y: 30),
                        control: CGPoint(x: 25, y: 38)
                    )
                }
                .stroke(.white, lineWidth: 2)
                .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Hoi! 👋")
                    .font(.headline)
                Text(MascotMessages.randomEncouragement())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

// MARK: - Quick Add Card
struct QuickAddCard: View {
    @Binding var text: String
    @Binding var isRecording: Bool
    let onAdd: () -> Void
    let onVoiceStart: () -> Void
    let onVoiceStop: () -> Void
    let audioLevel: Float

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Snel iets toevoegen...", text: $text)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onSubmit(onAdd)

                if !text.isEmpty {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.purple)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )

            // Voice button
            VoiceRecordButton(
                isRecording: $isRecording,
                audioLevel: audioLevel,
                onStart: onVoiceStart,
                onStop: onVoiceStop
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

// MARK: - Voice Record Button
struct VoiceRecordButton: View {
    @Binding var isRecording: Bool
    let audioLevel: Float
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        Button {
            if isRecording {
                onStop()
            } else {
                onStart()
            }
        } label: {
            HStack {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.title3)
                Text(isRecording ? "Stop opname" : "Spreek je taak in")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isRecording ? .red : .purple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isRecording ? Color.red.opacity(0.1) : Color.purple.opacity(0.1))
            )
            .overlay {
                if isRecording {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(Double(audioLevel)), lineWidth: 2)
                        .animation(.easeOut(duration: 0.1), value: audioLevel)
                }
            }
        }
    }
}

// MARK: - Today's Focus Section
struct TodaysFocusSection: View {
    let tasks: [WGTask]
    let onTap: (WGTask) -> Void
    let onComplete: (WGTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vandaag")
                    .font(.headline)
                Spacer()
                Text("\(tasks.count) microstappen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if tasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "Alles gedaan!",
                    subtitle: "Of voeg iets toe hierboven"
                )
            } else {
                ForEach(tasks) { task in
                    MicroStepCard(
                        task: task,
                        onTap: { onTap(task) },
                        onComplete: { onComplete(task) }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

// MARK: - MicroStep Card
struct MicroStepCard: View {
    let task: WGTask
    let onTap: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.displayMicroStep)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(task.category.icon)
                    Text(task.effort.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Suggestions Section
struct SuggestionsSection: View {
    let suggestions: [TaskSuggestion]
    let quickWin: TaskSuggestion?
    let onSelect: (TaskSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wat kan ik oppakken?")
                .font(.headline)

            ForEach(suggestions) { suggestion in
                SuggestionCard(suggestion: suggestion, onSelect: { onSelect(suggestion) })
            }

            if let quickWin = quickWin {
                Divider()
                    .padding(.vertical, 4)

                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Text("Quick Win")
                        .font(.subheadline.weight(.medium))
                }

                SuggestionCard(suggestion: quickWin, isQuickWin: true, onSelect: { onSelect(quickWin) })
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

// MARK: - Suggestion Card
struct SuggestionCard: View {
    let suggestion: TaskSuggestion
    var isQuickWin = false
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(suggestion.category.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.displayText)
                    .font(.subheadline)
                    .lineLimit(2)

                if let taskTitle = suggestion.taskTitle {
                    Text(taskTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("~\(suggestion.estimatedMinutes) min")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(.tertiarySystemBackground))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isQuickWin ? Color.yellow.opacity(0.1) : Color(.secondarySystemBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Quick Stats Card
struct QuickStatsCard: View {
    @EnvironmentObject var gamificationEngine: GamificationEngine

    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "star.fill",
                value: "\(gamificationEngine.totalPoints)",
                label: "Punten",
                color: .yellow
            )

            Divider()
                .frame(height: 30)

            StatItem(
                icon: "flame.fill",
                value: "\(gamificationEngine.currentStreak)",
                label: "Streak",
                color: .orange
            )

            Divider()
                .frame(height: 30)

            StatItem(
                icon: "trophy.fill",
                value: "Lvl \(gamificationEngine.currentLevel)",
                label: "Level",
                color: .purple
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    HomeView()
        .environmentObject(TaskStore())
        .environmentObject(GamificationEngine())
}
