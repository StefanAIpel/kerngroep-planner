//
//  Badge.swift
//  Werkgeheugen
//
//  Achievement badges for gamification
//

import Foundation
import SwiftData

// MARK: - Badge Type
enum BadgeType: String, Codable, CaseIterable {
    case opDreef = "opDreef"              // 3 dagen op rij check-in
    case financienNinja = "financienNinja" // 5 financiën-taken afgerond
    case microMaster = "microMaster"       // 25 microstappen gedaan
    case inboxZero = "inboxZero"           // Inbox volledig leeg
    case focusHeld = "focusHeld"           // 10 Focus Mode sessies
    case weekWarrior = "weekWarrior"       // 7 dagen streak
    case centuryClub = "centuryClub"       // 100 taken afgerond
    case voiceChampion = "voiceChampion"   // 20 voice captures
    case earlyBird = "earlyBird"           // Check-in voor 9:00
    case nightOwl = "nightOwl"             // Avond check-in 5x

    var title: String {
        switch self {
        case .opDreef: return "Op Dreef"
        case .financienNinja: return "Financiën Ninja"
        case .microMaster: return "Micro Master"
        case .inboxZero: return "Inbox Zero"
        case .focusHeld: return "Focus Held"
        case .weekWarrior: return "Week Warrior"
        case .centuryClub: return "Century Club"
        case .voiceChampion: return "Voice Champion"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        }
    }

    var description: String {
        switch self {
        case .opDreef: return "3 dagen op rij check-in gedaan"
        case .financienNinja: return "5 financiën-taken afgerond"
        case .microMaster: return "25 microstappen voltooid"
        case .inboxZero: return "Inbox volledig leeg gemaakt"
        case .focusHeld: return "10 Focus Mode sessies voltooid"
        case .weekWarrior: return "7 dagen streak behaald"
        case .centuryClub: return "100 taken afgerond"
        case .voiceChampion: return "20 voice captures gemaakt"
        case .earlyBird: return "Check-in gedaan voor 9:00"
        case .nightOwl: return "5x avond check-in voltooid"
        }
    }

    var icon: String {
        switch self {
        case .opDreef: return "🔥"
        case .financienNinja: return "💰"
        case .microMaster: return "⚡"
        case .inboxZero: return "📥"
        case .focusHeld: return "🎯"
        case .weekWarrior: return "⚔️"
        case .centuryClub: return "💯"
        case .voiceChampion: return "🎤"
        case .earlyBird: return "🌅"
        case .nightOwl: return "🦉"
        }
    }

    var requiredValue: Int {
        switch self {
        case .opDreef: return 3
        case .financienNinja: return 5
        case .microMaster: return 25
        case .inboxZero: return 1
        case .focusHeld: return 10
        case .weekWarrior: return 7
        case .centuryClub: return 100
        case .voiceChampion: return 20
        case .earlyBird: return 1
        case .nightOwl: return 5
        }
    }
}

// MARK: - Badge Model (SwiftData)
@Model
final class Badge {
    var id: UUID
    var typeRaw: String
    var earnedAt: Date
    var isNew: Bool

    var type: BadgeType {
        get { BadgeType(rawValue: typeRaw) ?? .opDreef }
        set { typeRaw = newValue.rawValue }
    }

    init(type: BadgeType) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.earnedAt = Date()
        self.isNew = true
    }

    func markAsSeen() {
        isNew = false
    }
}

// MARK: - Badge Checker
struct BadgeChecker {
    static func checkForNewBadges(stats: UserStats, earnedBadges: [Badge]) -> [BadgeType] {
        var newBadges: [BadgeType] = []
        let earnedTypes = Set(earnedBadges.map { $0.type })

        // Op Dreef: 3 dagen streak
        if !earnedTypes.contains(.opDreef) && stats.currentStreak >= 3 {
            newBadges.append(.opDreef)
        }

        // Week Warrior: 7 dagen streak
        if !earnedTypes.contains(.weekWarrior) && stats.currentStreak >= 7 {
            newBadges.append(.weekWarrior)
        }

        // Micro Master: 25 microstappen
        if !earnedTypes.contains(.microMaster) && stats.microStepsCompleted >= 25 {
            newBadges.append(.microMaster)
        }

        // Focus Held: 10 focus sessies
        if !earnedTypes.contains(.focusHeld) && stats.focusSessionsCompleted >= 10 {
            newBadges.append(.focusHeld)
        }

        // Century Club: 100 taken
        if !earnedTypes.contains(.centuryClub) && stats.tasksCompleted >= 100 {
            newBadges.append(.centuryClub)
        }

        // Voice Champion: 20 voice captures
        if !earnedTypes.contains(.voiceChampion) && stats.voiceCapturesUsed >= 20 {
            newBadges.append(.voiceChampion)
        }

        return newBadges
    }

    static func checkFinancienNinja(financienTasksCompleted: Int, earnedBadges: [Badge]) -> Bool {
        let earnedTypes = Set(earnedBadges.map { $0.type })
        return !earnedTypes.contains(.financienNinja) && financienTasksCompleted >= 5
    }

    static func checkInboxZero(inboxCount: Int, earnedBadges: [Badge]) -> Bool {
        let earnedTypes = Set(earnedBadges.map { $0.type })
        return !earnedTypes.contains(.inboxZero) && inboxCount == 0
    }
}
