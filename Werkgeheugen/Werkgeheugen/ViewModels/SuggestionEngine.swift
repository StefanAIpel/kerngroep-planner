//
//  SuggestionEngine.swift
//  Werkgeheugen
//
//  Smart suggestions for "Wat kan ik oppakken?"
//

import Foundation
import SwiftUI

// MARK: - Suggestion Model
struct TaskSuggestion: Identifiable {
    let id = UUID()
    let task: WGTask?
    let category: TaskCategory
    let microStep: String
    let estimatedMinutes: Int
    let isDefaultAction: Bool

    var displayText: String {
        if let task = task {
            return task.displayMicroStep
        }
        return microStep
    }

    var taskTitle: String? {
        task?.title
    }
}

// MARK: - Suggestion Engine
@MainActor
class SuggestionEngine: ObservableObject {
    @Published var dailySuggestions: [TaskSuggestion] = []
    @Published var quickWin: TaskSuggestion?

    // MARK: - Generate Suggestions

    func generateSuggestions(from tasks: [WGTask]) {
        dailySuggestions = []

        // Get one suggestion per important category
        let priorityCategories: [TaskCategory] = [.werk, .gezin, .financien]

        for category in priorityCategories {
            if let suggestion = bestSuggestion(for: category, from: tasks) {
                dailySuggestions.append(suggestion)
            }
        }

        // Find the quickest win (smallest effort, highest priority)
        quickWin = findQuickWin(from: tasks)

        // Ensure we have at least 3 suggestions
        if dailySuggestions.count < 3 {
            fillWithDefaults()
        }
    }

    // MARK: - Best Suggestion per Category

    func bestSuggestion(for category: TaskCategory, from tasks: [WGTask]) -> TaskSuggestion {
        let categoryTasks = tasks.filter {
            $0.category == category &&
            $0.status == .active
        }

        if categoryTasks.isEmpty {
            // Return default action for empty category
            return TaskSuggestion(
                task: nil,
                category: category,
                microStep: category.defaultMicroAction,
                estimatedMinutes: 2,
                isDefaultAction: true
            )
        }

        // Sort by: effort (smallest first), then priority (highest first), then oldest
        let sorted = categoryTasks.sorted { a, b in
            if a.effort.sortOrder != b.effort.sortOrder {
                return a.effort.sortOrder < b.effort.sortOrder
            }
            if a.priority.rawValue != b.priority.rawValue {
                return a.priority.rawValue < b.priority.rawValue
            }
            return a.createdAt < b.createdAt
        }

        guard let best = sorted.first else {
            return TaskSuggestion(
                task: nil,
                category: category,
                microStep: category.defaultMicroAction,
                estimatedMinutes: 2,
                isDefaultAction: true
            )
        }

        return TaskSuggestion(
            task: best,
            category: category,
            microStep: best.displayMicroStep,
            estimatedMinutes: best.effort.minutes,
            isDefaultAction: false
        )
    }

    // MARK: - Quick Win Finder

    func findQuickWin(from tasks: [WGTask]) -> TaskSuggestion? {
        let activeTasks = tasks.filter { $0.status == .active }

        // Find micro or klein effort tasks
        let quickTasks = activeTasks.filter {
            $0.effort == .micro || $0.effort == .klein
        }

        if quickTasks.isEmpty {
            // Return a generic quick win suggestion
            return TaskSuggestion(
                task: nil,
                category: .overig,
                microStep: "Kies 1 kleine taak uit je lijst",
                estimatedMinutes: 5,
                isDefaultAction: true
            )
        }

        // Sort by priority (highest first), then effort (smallest first)
        let sorted = quickTasks.sorted { a, b in
            if a.priority.rawValue != b.priority.rawValue {
                return a.priority.rawValue < b.priority.rawValue
            }
            return a.effort.sortOrder < b.effort.sortOrder
        }

        guard let best = sorted.first else { return nil }

        return TaskSuggestion(
            task: best,
            category: best.category,
            microStep: best.displayMicroStep,
            estimatedMinutes: best.effort.minutes,
            isDefaultAction: false
        )
    }

    // MARK: - Fill with Defaults

    private func fillWithDefaults() {
        let defaults: [(TaskCategory, String, Int)] = [
            (.werk, "Check je mail inbox", 5),
            (.gezin, "Stuur een berichtje naar iemand", 2),
            (.financien, "Bekijk 1 bankafschrift", 3)
        ]

        for (category, action, minutes) in defaults {
            if !dailySuggestions.contains(where: { $0.category == category }) {
                dailySuggestions.append(TaskSuggestion(
                    task: nil,
                    category: category,
                    microStep: action,
                    estimatedMinutes: minutes,
                    isDefaultAction: true
                ))
            }

            if dailySuggestions.count >= 3 { break }
        }
    }

    // MARK: - Next Micro Step per Category

    func nextMicroStep(for category: TaskCategory, from tasks: [WGTask]) -> (task: WGTask?, step: String) {
        let suggestion = bestSuggestion(for: category, from: tasks)
        return (suggestion.task, suggestion.microStep)
    }

    // MARK: - Today's Focus Tasks (max 3)

    func todaysFocus(from tasks: [WGTask]) -> [WGTask] {
        let active = tasks.filter { $0.status == .active }

        // Priority: P1 urgent > P1 > P2 urgent > P2 > smallest effort
        let sorted = active.sorted { a, b in
            // Urgent P1 first
            if a.isUrgent && a.priority == .p1 && !(b.isUrgent && b.priority == .p1) {
                return true
            }
            if b.isUrgent && b.priority == .p1 && !(a.isUrgent && a.priority == .p1) {
                return false
            }

            // Then by priority
            if a.priority.rawValue != b.priority.rawValue {
                return a.priority.rawValue < b.priority.rawValue
            }

            // Then by effort (smaller first)
            if a.effort.sortOrder != b.effort.sortOrder {
                return a.effort.sortOrder < b.effort.sortOrder
            }

            // Then by due date (sooner first)
            if let aDate = a.dueDate, let bDate = b.dueDate {
                return aDate < bDate
            }
            if a.dueDate != nil { return true }
            if b.dueDate != nil { return false }

            // Then by creation date (older first)
            return a.createdAt < b.createdAt
        }

        return Array(sorted.prefix(3))
    }

    // MARK: - Tomorrow's Top Pick

    func tomorrowTopPick(from tasks: [WGTask]) -> WGTask? {
        let active = tasks.filter { $0.status == .active }

        // Find the most impactful task for tomorrow
        // Prefer: P1 > has due date soon > oldest P2

        let sorted = active.sorted { a, b in
            if a.priority.rawValue != b.priority.rawValue {
                return a.priority.rawValue < b.priority.rawValue
            }

            // Due date within next 3 days gets priority
            let threeDays = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
            let aHasDueSoon = a.dueDate != nil && a.dueDate! <= threeDays
            let bHasDueSoon = b.dueDate != nil && b.dueDate! <= threeDays

            if aHasDueSoon && !bHasDueSoon { return true }
            if bHasDueSoon && !aHasDueSoon { return false }

            return a.createdAt < b.createdAt
        }

        return sorted.first
    }
}

// MARK: - Mascot Messages
struct MascotMessages {
    static let encouragements = [
        "Je kan dit! 💪",
        "Eén stapje maar!",
        "Kleine stappen, grote resultaten!",
        "Begin gewoon, de rest volgt! 🌟",
        "Elke stap telt!",
        "Je bent op de goede weg! 🚀"
    ]

    static let celebrations = [
        "Gelukt! 🎉",
        "Lekker bezig! ⭐",
        "Mooi gedaan! 🌟",
        "Yes! Weer eentje! 💪",
        "Top! Ga zo door! 🔥"
    ]

    static let eveningMessages = [
        "Tijd om te rusten, morgen weer! 🌙",
        "Goed gedaan vandaag! Slaap lekker! 😴",
        "Even opladen voor morgen! ✨"
    ]

    static let morningMessages = [
        "Goeiemorgen! Klaar voor een nieuwe dag? ☀️",
        "Nieuwe dag, nieuwe kansen! 🌅",
        "Laten we beginnen! 💪"
    ]

    static func randomEncouragement() -> String {
        encouragements.randomElement() ?? encouragements[0]
    }

    static func randomCelebration() -> String {
        celebrations.randomElement() ?? celebrations[0]
    }

    static func randomEvening() -> String {
        eveningMessages.randomElement() ?? eveningMessages[0]
    }

    static func randomMorning() -> String {
        morningMessages.randomElement() ?? morningMessages[0]
    }
}
