//
//  GamificationEngine.swift
//  Werkgeheugen
//
//  Points, streaks, badges, and celebrations
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class GamificationEngine: ObservableObject {
    @Published var stats: UserStats?
    @Published var badges: [Badge] = []
    @Published var showConfetti = false
    @Published var showBadgeUnlock = false
    @Published var newBadge: Badge?
    @Published var lastPointsEarned = 0
    @Published var showPointsPopup = false

    private var modelContext: ModelContext?

    // MARK: - Setup

    func setup(with modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchOrCreateStats()
        fetchBadges()
    }

    private func fetchOrCreateStats() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<UserStats>()
        do {
            let existingStats = try modelContext.fetch(descriptor)
            if let existing = existingStats.first {
                stats = existing
            } else {
                let newStats = UserStats()
                modelContext.insert(newStats)
                try modelContext.save()
                stats = newStats
            }
        } catch {
            print("Failed to fetch/create stats: \(error)")
        }
    }

    private func fetchBadges() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<Badge>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        do {
            badges = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch badges: \(error)")
        }
    }

    // MARK: - Point Actions

    func awardMicroStepPoints() {
        guard let stats = stats else { return }
        stats.completeMicroStep()
        showPointsAnimation(PointsConfig.microStepDone)
        checkForNewBadges()
        saveContext()
    }

    func awardTaskCompletionPoints() {
        guard let stats = stats else { return }
        stats.completeTask()
        showPointsAnimation(PointsConfig.taskDone)
        triggerConfetti()
        checkForNewBadges()
        saveContext()
    }

    func awardTriagePoints(count: Int) {
        guard let stats = stats else { return }
        stats.triageInbox(count: count)
        if count >= 5 {
            showPointsAnimation(PointsConfig.inbox5Triaged)
        }
        saveContext()
    }

    func awardCheckInPoints() {
        guard let stats = stats else { return }
        stats.completeCheckIn()
        showPointsAnimation(PointsConfig.checkInDone)
        triggerConfetti()
        checkForNewBadges()
        saveContext()
    }

    func awardVoiceCapturePoints() {
        guard let stats = stats else { return }
        stats.useVoiceCapture()
        showPointsAnimation(PointsConfig.voiceCapture)
        saveContext()
    }

    func awardFocusSessionPoints() {
        guard let stats = stats else { return }
        stats.completeFocusSession()
        showPointsAnimation(PointsConfig.focusSession)
        checkForNewBadges()
        saveContext()
    }

    // MARK: - Animations

    private func showPointsAnimation(_ points: Int) {
        lastPointsEarned = points
        showPointsPopup = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Auto-hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showPointsPopup = false
        }
    }

    func triggerConfetti() {
        showConfetti = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Auto-hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showConfetti = false
        }
    }

    // MARK: - Badge Checking

    func checkForNewBadges() {
        guard let stats = stats else { return }

        let newBadgeTypes = BadgeChecker.checkForNewBadges(stats: stats, earnedBadges: badges)

        for badgeType in newBadgeTypes {
            awardBadge(badgeType)
        }
    }

    func checkInboxZero(inboxCount: Int) {
        if BadgeChecker.checkInboxZero(inboxCount: inboxCount, earnedBadges: badges) {
            awardBadge(.inboxZero)
        }
    }

    func checkFinancienBadge(completedCount: Int) {
        if BadgeChecker.checkFinancienNinja(financienTasksCompleted: completedCount, earnedBadges: badges) {
            awardBadge(.financienNinja)
        }
    }

    private func awardBadge(_ type: BadgeType) {
        guard let modelContext = modelContext else { return }

        // Check if already earned
        if badges.contains(where: { $0.type == type }) { return }

        let badge = Badge(type: type)
        modelContext.insert(badge)

        newBadge = badge
        showBadgeUnlock = true
        triggerConfetti()

        fetchBadges()
        saveContext()

        // Auto-hide badge popup
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showBadgeUnlock = false
            self?.newBadge = nil
        }
    }

    // MARK: - Stats Helpers

    var totalPoints: Int {
        stats?.totalPoints ?? 0
    }

    var currentLevel: Int {
        stats?.level ?? 1
    }

    var currentStreak: Int {
        stats?.currentStreak ?? 0
    }

    var levelProgress: Double {
        stats?.levelProgress ?? 0
    }

    var pointsToNextLevel: Int {
        stats?.pointsToNextLevel ?? 100
    }

    var hasCheckedInToday: Bool {
        stats?.hasCheckedInToday ?? false
    }

    // MARK: - Save

    private func saveContext() {
        guard let modelContext = modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save gamification context: \(error)")
        }
    }
}

// MARK: - Haptic Helpers
struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
