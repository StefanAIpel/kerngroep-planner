//
//  CategoriesView.swift
//  Werkgeheugen
//
//  Overview of all categories with their tasks
//

import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var taskStore: TaskStore

    @State private var selectedCategory: TaskCategory?
    @State private var showTaskDetail = false
    @State private var selectedTask: WGTask?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(TaskCategory.allCases) { category in
                        CategoryCard(
                            category: category,
                            taskCount: taskStore.tasks(for: category).count
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Categorieën")
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedCategory) { category in
                CategoryDetailView(category: category)
            }
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: TaskCategory
    let taskCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(category.icon)
                    .font(.system(size: 40))

                Text(category.label)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(taskCount) taken")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Detail View
struct CategoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var gamificationEngine: GamificationEngine

    let category: TaskCategory

    @State private var showAddTask = false
    @State private var newTaskTitle = ""
    @State private var selectedTask: WGTask?
    @State private var showFocusMode = false
    @StateObject private var suggestionEngine = SuggestionEngine()

    var categoryTasks: [WGTask] {
        taskStore.tasks(for: category)
    }

    var body: some View {
        NavigationStack {
            List {
                // Next microstep suggestion
                Section {
                    let (task, step) = suggestionEngine.nextMicroStep(for: category, from: taskStore.tasks)
                    NextMicroStepRow(
                        task: task,
                        microStep: step,
                        onStart: {
                            if let task = task {
                                selectedTask = task
                                showFocusMode = true
                            }
                        }
                    )
                } header: {
                    Text("Volgende stap")
                }

                // Active tasks
                Section {
                    if categoryTasks.isEmpty {
                        Text("Geen actieve taken")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categoryTasks) { task in
                            TaskRow(task: task) {
                                selectedTask = task
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    taskStore.deleteTask(task)
                                } label: {
                                    Label("Verwijder", systemImage: "trash")
                                }

                                Button {
                                    _ = taskStore.completeTask(task)
                                    gamificationEngine.awardTaskCompletionPoints()
                                } label: {
                                    Label("Klaar", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    taskStore.snoozeTask(task)
                                } label: {
                                    Label("Snooze", systemImage: "moon")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                } header: {
                    Text("Taken (\(categoryTasks.count))")
                }

                // Quick add
                Section {
                    HStack {
                        TextField("Nieuwe taak...", text: $newTaskTitle)
                            .submitLabel(.done)
                            .onSubmit(addTask)

                        if !newTaskTitle.isEmpty {
                            Button(action: addTask) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(category.icon) \(category.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Klaar") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task)
            }
            .fullScreenCover(isPresented: $showFocusMode) {
                if let task = selectedTask {
                    FocusModeView(task: task) {
                        showFocusMode = false
                        taskStore.fetchTasks()
                    }
                }
            }
            .onAppear {
                suggestionEngine.generateSuggestions(from: taskStore.tasks)
            }
        }
    }

    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        taskStore.addTask(title: trimmed, category: category)
        newTaskTitle = ""
        HapticFeedback.medium()
    }
}

// MARK: - Next MicroStep Row
struct NextMicroStepRow: View {
    let task: WGTask?
    let microStep: String
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .font(.title2)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text(microStep)
                    .font(.subheadline.weight(.medium))

                if let task = task {
                    Text(task.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onStart) {
                Text("Start")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.purple))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let task: WGTask
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .stroke(priorityColor, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if task.isUrgent {
                            Image(systemName: "exclamationmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(priorityColor)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(task.effort.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if let dueDate = task.dueDate {
                            Text(dueDate, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    var priorityColor: Color {
        switch task.priority {
        case .p1: return .red
        case .p2: return .yellow
        case .p3: return .green
        }
    }
}

#Preview {
    CategoriesView()
        .environmentObject(TaskStore())
        .environmentObject(GamificationEngine())
}
