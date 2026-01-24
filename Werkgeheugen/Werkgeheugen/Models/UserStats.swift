//
//  UserStats.swift
//  Werkgeheugen
//
//  Gamification stats and streaks
//

import Foundation
import SwiftData

@Model
final class UserStats {
    var id: UUID
    var totalPoints: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastCheckInDate: Date?
    var tasksCompleted: Int
    var microStepsCompleted: Int
    var inboxTriaged: Int
    var voiceCapturesUsed: Int
    var focusSessionsCompleted: Int
    var level: Int
    var createdAt: Date

    init() {
        self.id = UUID()
        self.totalPoints = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastCheckInDate = nil
        self.tasksCompleted = 0
        self.microStepsCompleted = 0
        self.inboxTriaged = 0
        self.voiceCapturesUsed = 0
        self.focusSessionsCompleted = 0
        self.level = 1
        self.createdAt = Date()
    }

    // MARK: - Point Actions

    func addPoints(_ points: Int) {
        totalPoints += points
        updateLevel()
    }

    func completeMicroStep() {
        microStepsCompleted += 1
        addPoints(10)
    }

    func completeTask() {
        tasksCompleted += 1
        addPoints(25)
    }

    func triageInbox(count: Int) {
        inboxTriaged += count
        if count >= 5 {
            addPoints(15)
        }
    }

    func completeCheckIn() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastCheckIn = lastCheckInDate {
            let lastCheckInDay = calendar.startOfDay(for: lastCheckIn)
            let daysDiff = calendar.dateComponents([.day], from: lastCheckInDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // daysDiff == 0 means already checked in today
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastCheckInDate = today
        addPoints(20)
    }

    func useVoiceCapture() {
        voiceCapturesUsed += 1
        addPoints(5)
    }

    func completeFocusSession() {
        focusSessionsCompleted += 1
        addPoints(15)
    }

    // MARK: - Level System

    private func updateLevel() {
        // Simple level system: every 100 points = 1 level
        level = max(1, (totalPoints / 100) + 1)
    }

    var pointsToNextLevel: Int {
        let nextLevelPoints = level * 100
        return max(0, nextLevelPoints - totalPoints)
    }

    var levelProgress: Double {
        let currentLevelStart = (level - 1) * 100
        let pointsInLevel = totalPoints - currentLevelStart
        return min(1.0, Double(pointsInLevel) / 100.0)
    }

    // MARK: - Streak Helpers

    var hasCheckedInToday: Bool {
        guard let lastCheckIn = lastCheckInDate else { return false }
        return Calendar.current.isDateInToday(lastCheckIn)
    }

    var streakEmoji: String {
        switch currentStreak {
        case 0: return "💤"
        case 1...2: return "🔥"
        case 3...6: return "🔥🔥"
        case 7...13: return "🔥🔥🔥"
        case 14...29: return "⭐🔥"
        default: return "🌟🔥"
        }
    }
}

// MARK: - Points Constants
struct PointsConfig {
    static let microStepDone = 10
    static let taskDone = 25
    static let inbox5Triaged = 15
    static let checkInDone = 20
    static let voiceCapture = 5
    static let focusSession = 15
}
