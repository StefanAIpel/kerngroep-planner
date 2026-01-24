//
//  TaskStore.swift
//  Werkgeheugen
//
//  Main ViewModel for task management
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class TaskStore: ObservableObject {
    @Published var tasks: [WGTask] = []
    @Published var selectedTask: WGTask?
    @Published var showQuickAdd = false
    @Published var quickAddText = ""
    @Published var isRecording = false
    @Published var currentTriageIndex = 0

    private var modelContext: ModelContext?

    // MARK: - Setup

    func setup(with modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTasks()
    }

    // MARK: - Fetch

    func fetchTasks() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<WGTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            tasks = try modelContext.fetch(descriptor)
            checkSnoozedTasks()
        } catch {
            print("Failed to fetch tasks: \(error)")
        }
    }

    // MARK: - Filtered Lists

    var inboxTasks: [WGTask] {
        tasks.filter { $0.status == .inbox }
    }

    var activeTasks: [WGTask] {
        tasks.filter { $0.status == .active }
    }

    var doneTasks: [WGTask] {
        tasks.filter { $0.status == .done }
    }

    var snoozedTasks: [WGTask] {
        tasks.filter { $0.status == .snoozed }
    }

    var todayCompletedTasks: [WGTask] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.isDateInToday(completedAt)
        }
    }

    func tasks(for category: TaskCategory) -> [WGTask] {
        tasks.filter { $0.category == category && $0.status != .done }
    }

    // MARK: - CRUD Operations

    func addTask(
        title: String,
        category: TaskCategory? = nil,
        priority: TaskPriority = .p3,
        effort: TaskEffort = .klein,
        microStep: String = "",
        audioFilePath: String? = nil
    ) {
        guard let modelContext = modelContext else { return }

        let task = WGTask(
            title: title,
            category: category ?? .overig,
            priority: priority,
            effort: effort,
            status: category == nil ? .inbox : .active,
            microStep: microStep,
            audioFilePath: audioFilePath
        )

        modelContext.insert(task)
        saveContext()
        fetchTasks()
    }

    func quickAdd() {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        addTask(title: trimmed)
        quickAddText = ""
        showQuickAdd = false
    }

    func updateTask(_ task: WGTask) {
        task.updatedAt = Date()
        saveContext()
        fetchTasks()
    }

    func deleteTask(_ task: WGTask) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(task)
        saveContext()
        fetchTasks()
    }

    func completeTask(_ task: WGTask) -> Int {
        task.markAsDone()
        let points = PointsConfig.taskDone
        task.pointsEarned += points
        saveContext()
        fetchTasks()
        return points
    }

    func completeMicroStep(_ task: WGTask) -> Int {
        // Micro step is done, but task continues
        let points = PointsConfig.microStepDone
        task.pointsEarned += points
        task.updatedAt = Date()
        saveContext()
        return points
    }

    func snoozeTask(_ task: WGTask, hours: Int = 1) {
        task.snooze(for: hours)
        saveContext()
        fetchTasks()
    }

    func activateTask(_ task: WGTask) {
        task.activate()
        saveContext()
        fetchTasks()
    }

    // MARK: - Triage

    func triageTask(_ task: WGTask, category: TaskCategory, priority: TaskPriority, microStep: String) {
        task.category = category
        task.priority = priority
        task.microStep = microStep
        task.status = .active
        task.updatedAt = Date()
        saveContext()
        fetchTasks()
    }

    var currentTriageTask: WGTask? {
        let inbox = inboxTasks
        guard currentTriageIndex < inbox.count else { return nil }
        return inbox[currentTriageIndex]
    }

    func nextTriageTask() {
        currentTriageIndex += 1
        if currentTriageIndex >= inboxTasks.count {
            currentTriageIndex = 0
        }
    }

    func resetTriage() {
        currentTriageIndex = 0
    }

    // MARK: - Snoozed Check

    private func checkSnoozedTasks() {
        for task in snoozedTasks where task.isSnoozedAndReady {
            task.status = .active
            task.snoozeUntil = nil
        }
        saveContext()
    }

    // MARK: - Save

    private func saveContext() {
        guard let modelContext = modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    // MARK: - Export

    func exportToJSON() -> String {
        let tasksDict = tasks.map { $0.asDict }
        guard let data = try? JSONSerialization.data(withJSONObject: tasksDict, options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    func exportToCSV() -> String {
        var csv = WGTask.csvHeader + "\n"
        for task in tasks {
            csv += task.asCSVRow + "\n"
        }
        return csv
    }
}
