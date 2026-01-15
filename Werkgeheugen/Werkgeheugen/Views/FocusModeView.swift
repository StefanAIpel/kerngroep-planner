//
//  FocusModeView.swift
//  Werkgeheugen
//
//  Full-screen focus on a single microstep
//

import SwiftUI

struct FocusModeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var gamificationEngine: GamificationEngine

    let task: WGTask
    let onDismiss: () -> Void

    @State private var showSplitSheet = false
    @State private var splitStepText = ""
    @State private var showSnoozeOptions = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showCelebration = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        stopTimer()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()

                Spacer()

                // Category indicator
                VStack(spacing: 8) {
                    Text(task.category.icon)
                        .font(.system(size: 50))

                    Text(task.category.label)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Main microstep
                VStack(spacing: 16) {
                    Text("Je enige focus:")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))

                    Text(task.displayMicroStep)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Task title (smaller)
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Timer
                Text(formatTime(elapsedTime))
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 16)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    // Done button (big)
                    Button(action: completeMicroStep) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Klaar!")
                        }
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                        )
                    }

                    // Secondary actions
                    HStack(spacing: 12) {
                        Button(action: { showSnoozeOptions = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "moon.fill")
                                Text("Snooze")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.2))
                            )
                        }

                        Button(action: { showSplitSheet = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "scissors")
                                Text("Splits")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.2))
                            )
                        }

                        Button(action: completeTask) {
                            VStack(spacing: 4) {
                                Image(systemName: "flag.checkered")
                                Text("Hele taak")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.2))
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }

            // Celebration overlay
            if showCelebration {
                CelebrationOverlay()
            }
        }
        .onAppear {
            startTimer()
        }
        .confirmationDialog("Snooze", isPresented: $showSnoozeOptions) {
            Button("15 minuten") { snooze(minutes: 15) }
            Button("1 uur") { snooze(minutes: 60) }
            Button("3 uur") { snooze(minutes: 180) }
            Button("Morgen") { snoozeTomorrow() }
            Button("Annuleren", role: .cancel) { }
        }
        .sheet(isPresented: $showSplitSheet) {
            SplitStepSheet(
                originalStep: task.displayMicroStep,
                newStepText: $splitStepText,
                onSplit: splitStep
            )
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    private func completeMicroStep() {
        stopTimer()
        _ = taskStore.completeMicroStep(task)
        gamificationEngine.awardMicroStepPoints()
        gamificationEngine.awardFocusSessionPoints()

        showCelebration = true
        HapticFeedback.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onDismiss()
        }
    }

    private func completeTask() {
        stopTimer()
        _ = taskStore.completeTask(task)
        gamificationEngine.awardTaskCompletionPoints()
        gamificationEngine.awardFocusSessionPoints()

        showCelebration = true
        HapticFeedback.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onDismiss()
        }
    }

    private func snooze(minutes: Int) {
        stopTimer()
        taskStore.snoozeTask(task, hours: minutes / 60)
        HapticFeedback.medium()
        onDismiss()
    }

    private func snoozeTomorrow() {
        stopTimer()
        // Calculate hours until tomorrow 9 AM
        let calendar = Calendar.current
        var tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        tomorrow = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        let hours = Int(tomorrow.timeIntervalSinceNow / 3600)
        taskStore.snoozeTask(task, hours: hours)
        HapticFeedback.medium()
        onDismiss()
    }

    private func splitStep() {
        let trimmed = splitStepText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Update current task's microstep
        task.microStep = trimmed
        taskStore.updateTask(task)

        splitStepText = ""
        showSplitSheet = false
        HapticFeedback.medium()
    }
}

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 80))

                Text(MascotMessages.randomCelebration())
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Split Step Sheet
struct SplitStepSheet: View {
    @Environment(\.dismiss) private var dismiss

    let originalStep: String
    @Binding var newStepText: String
    let onSplit: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Originele stap:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(originalStep)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Kleinere eerste stap:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Bijv. 'Open alleen de app'", text: $newStepText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                }

                Text("💡 Tip: Maak de stap zo klein dat je er niet over hoeft na te denken")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("Splits in kleinere stap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Opslaan") {
                        onSplit()
                    }
                    .disabled(newStepText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    FocusModeView(
        task: WGTask(title: "Test taak", microStep: "Open de app"),
        onDismiss: {}
    )
    .environmentObject(TaskStore())
    .environmentObject(GamificationEngine())
}
