//
//  InboxView.swift
//  Werkgeheugen
//
//  Swipe-based inbox triage - one task at a time
//

import SwiftUI

struct InboxView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var gamificationEngine: GamificationEngine

    @State private var currentIndex = 0
    @State private var offset: CGSize = .zero
    @State private var selectedCategory: TaskCategory?
    @State private var selectedPriority: TaskPriority = .p3
    @State private var microStepText = ""
    @State private var triageCount = 0
    @State private var showTriageComplete = false

    var inboxTasks: [WGTask] {
        taskStore.inboxTasks
    }

    var currentTask: WGTask? {
        guard currentIndex < inboxTasks.count else { return nil }
        return inboxTasks[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if inboxTasks.isEmpty {
                    InboxEmptyView()
                } else if let task = currentTask {
                    VStack(spacing: 0) {
                        // Progress indicator
                        ProgressHeader(
                            current: currentIndex + 1,
                            total: inboxTasks.count,
                            triaged: triageCount
                        )

                        Spacer()

                        // Task card with swipe
                        TriageCard(
                            task: task,
                            offset: $offset,
                            selectedCategory: $selectedCategory,
                            selectedPriority: $selectedPriority,
                            microStepText: $microStepText,
                            onTriage: triageCurrentTask,
                            onSkip: skipTask,
                            onDelete: deleteTask
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                }
                                .onEnded { gesture in
                                    handleSwipe(gesture)
                                }
                        )

                        Spacer()

                        // Action buttons
                        TriageActions(
                            onTriage: triageCurrentTask,
                            onSkip: skipTask,
                            canTriage: selectedCategory != nil
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(inboxTasks.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .alert("Inbox Zero! 🎉", isPresented: $showTriageComplete) {
                Button("Top!") {
                    gamificationEngine.checkInboxZero(inboxCount: 0)
                }
            } message: {
                Text("Je hebt \(triageCount) items getriaged. Lekker bezig!")
            }
            .onAppear {
                resetTriage()
            }
        }
    }

    // MARK: - Actions

    private func resetTriage() {
        currentIndex = 0
        triageCount = 0
        resetSelections()
    }

    private func resetSelections() {
        selectedCategory = nil
        selectedPriority = .p3
        microStepText = ""
        offset = .zero
    }

    private func triageCurrentTask() {
        guard let task = currentTask, let category = selectedCategory else { return }

        taskStore.triageTask(
            task,
            category: category,
            priority: selectedPriority,
            microStep: microStepText
        )

        triageCount += 1
        if triageCount % 5 == 0 {
            gamificationEngine.awardTriagePoints(count: 5)
        }

        HapticFeedback.success()
        moveToNext()
    }

    private func skipTask() {
        HapticFeedback.light()
        moveToNext()
    }

    private func deleteTask() {
        guard let task = currentTask else { return }
        taskStore.deleteTask(task)
        HapticFeedback.warning()
        // Don't increment index since list shrinks
        if currentIndex >= inboxTasks.count {
            currentIndex = max(0, inboxTasks.count - 1)
        }
        resetSelections()
        checkCompletion()
    }

    private func moveToNext() {
        resetSelections()

        withAnimation(.spring(response: 0.3)) {
            if currentIndex < inboxTasks.count - 1 {
                currentIndex += 1
            } else {
                // Reached end
                checkCompletion()
            }
        }
    }

    private func checkCompletion() {
        if inboxTasks.isEmpty && triageCount > 0 {
            showTriageComplete = true
        }
    }

    private func handleSwipe(_ gesture: DragGesture.Value) {
        let horizontalAmount = gesture.translation.width
        let verticalAmount = gesture.translation.height

        withAnimation(.spring(response: 0.3)) {
            offset = .zero
        }

        // Swipe right = categorize
        if horizontalAmount > 100 && selectedCategory != nil {
            triageCurrentTask()
        }
        // Swipe left = skip
        else if horizontalAmount < -100 {
            skipTask()
        }
        // Swipe down = delete
        else if verticalAmount > 100 {
            deleteTask()
        }
    }
}

// MARK: - Progress Header
struct ProgressHeader: View {
    let current: Int
    let total: Int
    let triaged: Int

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(current), total: Double(total))
                .tint(.purple)

            HStack {
                Text("Taak \(current) van \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if triaged > 0 {
                    Text("\(triaged) getriaged ✓")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Triage Card
struct TriageCard: View {
    let task: WGTask
    @Binding var offset: CGSize
    @Binding var selectedCategory: TaskCategory?
    @Binding var selectedPriority: TaskPriority
    @Binding var microStepText: String
    let onTriage: () -> Void
    let onSkip: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Task title
            Text(task.title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // Category selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Categorie")
                    .font(.subheadline.weight(.medium))

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(TaskCategory.allCases) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            onSelect: { selectedCategory = category }
                        )
                    }
                }
            }

            // Priority selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Prioriteit")
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 8) {
                    ForEach(TaskPriority.allCases, id: \.rawValue) { priority in
                        PriorityChip(
                            priority: priority,
                            isSelected: selectedPriority == priority,
                            onSelect: { selectedPriority = priority }
                        )
                    }
                }
            }

            // Microstep input
            VStack(alignment: .leading, spacing: 8) {
                Text("Eerste microstap")
                    .font(.subheadline.weight(.medium))

                TextField("Bijv. 'Open de mail'", text: $microStepText)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .scaleEffect(1 - abs(offset.width) / 1000)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: TaskCategory
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onSelect()
        }) {
            VStack(spacing: 4) {
                Text(category.icon)
                    .font(.title3)
                Text(category.label)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.2) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Priority Chip
struct PriorityChip: View {
    let priority: TaskPriority
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onSelect()
        }) {
            Text(priority.label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple.opacity(0.2) : Color(.secondarySystemBackground))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Triage Actions
struct TriageActions: View {
    let onTriage: () -> Void
    let onSkip: () -> Void
    let canTriage: Bool

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onSkip) {
                Label("Later", systemImage: "arrow.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
            }

            Button(action: onTriage) {
                Label("Opslaan", systemImage: "checkmark")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canTriage ? Color.purple : Color.gray)
                    )
            }
            .disabled(!canTriage)
        }
    }
}

// MARK: - Empty View
struct InboxEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Inbox is leeg!")
                .font(.title2.weight(.semibold))

            Text("Gebruik Quick Add of Voice om\nnieuwe taken toe te voegen")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(.yellow)
        }
        .padding()
    }
}

#Preview {
    InboxView()
        .environmentObject(TaskStore())
        .environmentObject(GamificationEngine())
}
