//
//  WGTask.swift
//  Werkgeheugen
//
//  Core task model with SwiftData
//

import Foundation
import SwiftData

// MARK: - Task Priority
enum TaskPriority: Int, Codable, CaseIterable {
    case p1 = 1  // Urgent/Important
    case p2 = 2  // Important
    case p3 = 3  // Normal

    var label: String {
        switch self {
        case .p1: return "P1 🔴"
        case .p2: return "P2 🟡"
        case .p3: return "P3 🟢"
        }
    }

    var color: String {
        switch self {
        case .p1: return "red"
        case .p2: return "yellow"
        case .p3: return "green"
        }
    }
}

// MARK: - Task Effort
enum TaskEffort: String, Codable, CaseIterable {
    case micro = "micro"   // < 2 min
    case klein = "klein"   // 2-15 min
    case middel = "middel" // 15-60 min
    case groot = "groot"   // > 60 min

    var label: String {
        switch self {
        case .micro: return "⚡ Micro (< 2 min)"
        case .klein: return "🔹 Klein (2-15 min)"
        case .middel: return "🔷 Middel (15-60 min)"
        case .groot: return "🔶 Groot (> 1 uur)"
        }
    }

    var minutes: Int {
        switch self {
        case .micro: return 2
        case .klein: return 15
        case .middel: return 60
        case .groot: return 120
        }
    }

    var sortOrder: Int {
        switch self {
        case .micro: return 1
        case .klein: return 2
        case .middel: return 3
        case .groot: return 4
        }
    }
}

// MARK: - Task Status
enum TaskStatus: String, Codable, CaseIterable {
    case inbox = "inbox"
    case active = "active"
    case done = "done"
    case snoozed = "snoozed"

    var label: String {
        switch self {
        case .inbox: return "📥 Inbox"
        case .active: return "▶️ Actief"
        case .done: return "✅ Klaar"
        case .snoozed: return "😴 Snoozed"
        }
    }
}

// MARK: - Task Category
enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case werk = "werk"
    case apps = "apps"
    case voetbal = "voetbal"
    case straatambassadeurs = "straatambassadeurs"
    case gezin = "gezin"
    case financien = "financien"
    case overig = "overig"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .werk: return "Werk"
        case .apps: return "Apps"
        case .voetbal: return "Voetbal"
        case .straatambassadeurs: return "Straatambassadeurs"
        case .gezin: return "Gezin"
        case .financien: return "Financiën"
        case .overig: return "Overig"
        }
    }

    var icon: String {
        switch self {
        case .werk: return "🏢"
        case .apps: return "📱"
        case .voetbal: return "⚽"
        case .straatambassadeurs: return "🚶"
        case .gezin: return "👨‍👩‍👧"
        case .financien: return "💰"
        case .overig: return "📦"
        }
    }

    var defaultMicroAction: String {
        switch self {
        case .werk: return "Check 1 mail"
        case .apps: return "Open project, lees 1 TODO"
        case .voetbal: return "Check teamapp"
        case .straatambassadeurs: return "Plan 1 wandeling"
        case .gezin: return "Stuur 1 berichtje"
        case .financien: return "Check 1 rekening"
        case .overig: return "Bekijk 1 item"
        }
    }

    var color: String {
        switch self {
        case .werk: return "blue"
        case .apps: return "purple"
        case .voetbal: return "green"
        case .straatambassadeurs: return "orange"
        case .gezin: return "pink"
        case .financien: return "yellow"
        case .overig: return "gray"
        }
    }
}

// MARK: - WGTask Model (SwiftData)
@Model
final class WGTask {
    var id: UUID
    var title: String
    var notes: String
    var categoryRaw: String
    var priorityRaw: Int
    var effortRaw: String
    var statusRaw: String
    var isUrgent: Bool
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date
    var microStep: String
    var audioFilePath: String?
    var completedAt: Date?
    var snoozeUntil: Date?
    var pointsEarned: Int

    // Computed properties for enums
    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRaw) ?? .overig }
        set { categoryRaw = newValue.rawValue }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .p3 }
        set { priorityRaw = newValue.rawValue }
    }

    var effort: TaskEffort {
        get { TaskEffort(rawValue: effortRaw) ?? .klein }
        set { effortRaw = newValue.rawValue }
    }

    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .inbox }
        set { statusRaw = newValue.rawValue }
    }

    init(
        title: String,
        notes: String = "",
        category: TaskCategory = .overig,
        priority: TaskPriority = .p3,
        effort: TaskEffort = .klein,
        status: TaskStatus = .inbox,
        isUrgent: Bool = false,
        dueDate: Date? = nil,
        microStep: String = "",
        audioFilePath: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.categoryRaw = category.rawValue
        self.priorityRaw = priority.rawValue
        self.effortRaw = effort.rawValue
        self.statusRaw = status.rawValue
        self.isUrgent = isUrgent
        self.dueDate = dueDate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.microStep = microStep
        self.audioFilePath = audioFilePath
        self.completedAt = nil
        self.snoozeUntil = nil
        self.pointsEarned = 0
    }

    // MARK: - Helper Methods

    func markAsDone() {
        status = .done
        completedAt = Date()
        updatedAt = Date()
    }

    func snooze(for hours: Int = 1) {
        status = .snoozed
        snoozeUntil = Calendar.current.date(byAdding: .hour, value: hours, to: Date())
        updatedAt = Date()
    }

    func activate() {
        status = .active
        snoozeUntil = nil
        updatedAt = Date()
    }

    func moveToInbox() {
        status = .inbox
        updatedAt = Date()
    }

    var displayMicroStep: String {
        if microStep.isEmpty {
            return category.defaultMicroAction
        }
        return microStep
    }

    var isSnoozedAndReady: Bool {
        guard status == .snoozed, let snoozeUntil = snoozeUntil else {
            return false
        }
        return Date() >= snoozeUntil
    }
}

// MARK: - Task Export
extension WGTask {
    var asDict: [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "notes": notes,
            "category": categoryRaw,
            "priority": priorityRaw,
            "effort": effortRaw,
            "status": statusRaw,
            "isUrgent": isUrgent,
            "createdAt": createdAt.ISO8601Format(),
            "updatedAt": updatedAt.ISO8601Format(),
            "microStep": microStep,
            "pointsEarned": pointsEarned
        ]

        if let dueDate = dueDate {
            dict["dueDate"] = dueDate.ISO8601Format()
        }
        if let completedAt = completedAt {
            dict["completedAt"] = completedAt.ISO8601Format()
        }
        if let audioFilePath = audioFilePath {
            dict["audioFilePath"] = audioFilePath
        }

        return dict
    }

    var asCSVRow: String {
        let dueDateStr = dueDate?.ISO8601Format() ?? ""
        let completedAtStr = completedAt?.ISO8601Format() ?? ""
        return "\"\(title)\",\"\(notes)\",\(categoryRaw),\(priorityRaw),\(effortRaw),\(statusRaw),\(isUrgent),\(dueDateStr),\(createdAt.ISO8601Format()),\(completedAtStr),\"\(microStep)\""
    }

    static var csvHeader: String {
        "title,notes,category,priority,effort,status,isUrgent,dueDate,createdAt,completedAt,microStep"
    }
}
