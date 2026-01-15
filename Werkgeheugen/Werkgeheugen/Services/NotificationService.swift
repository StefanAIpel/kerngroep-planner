//
//  NotificationService.swift
//  Werkgeheugen
//
//  Local push notifications for reminders
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private let center = UNUserNotificationCenter.current()

    // Notification identifiers
    static let morningID = "werkgeheugen.morning"
    static let middayID = "werkgeheugen.midday"
    static let eveningID = "werkgeheugen.evening"

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Schedule Daily Notifications

    func scheduleAllNotifications(settings: UserSettings) {
        // Remove existing scheduled notifications
        center.removeAllPendingNotificationRequests()

        guard settings.notificationsEnabled else { return }

        if settings.morningEnabled {
            scheduleDailyNotification(
                id: Self.morningID,
                title: "Werkgeheugen ☀️",
                body: NotificationMessages.morning(strictness: settings.strictness),
                hour: settings.morningNotificationTime / 60,
                minute: settings.morningNotificationTime % 60
            )
        }

        if settings.middayEnabled {
            scheduleDailyNotification(
                id: Self.middayID,
                title: "Werkgeheugen 💪",
                body: NotificationMessages.midday(strictness: settings.strictness),
                hour: settings.middayNotificationTime / 60,
                minute: settings.middayNotificationTime % 60
            )
        }

        if settings.eveningEnabled {
            scheduleDailyNotification(
                id: Self.eveningID,
                title: "Werkgeheugen 🌙",
                body: NotificationMessages.evening(strictness: settings.strictness),
                hour: settings.eveningNotificationTime / 60,
                minute: settings.eveningNotificationTime % 60
            )
        }

        refreshPendingNotifications()
    }

    private func scheduleDailyNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        // Add category for actions
        content.categoryIdentifier = "WERKGEHEUGEN_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification \(id): \(error)")
            }
        }
    }

    // MARK: - One-time Notifications

    func scheduleSnoozeReminder(for task: WGTask, minutes: Int = 60) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Snooze voorbij!"
        content.body = "Tijd voor: \(task.displayMicroStep)"
        content.sound = .default
        content.userInfo = ["taskId": task.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "snooze.\(task.id.uuidString)", content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleDueDateReminder(for task: WGTask) {
        guard let dueDate = task.dueDate else { return }

        // Schedule reminder 1 hour before due date
        let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate) ?? dueDate

        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Deadline nadert!"
        content.body = task.title
        content.sound = .default
        content.userInfo = ["taskId": task.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderDate.timeIntervalSinceNow,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "due.\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Remove Notifications

    func removeNotification(for taskId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "snooze.\(taskId.uuidString)",
            "due.\(taskId.uuidString)"
        ])
    }

    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Pending Notifications

    func refreshPendingNotifications() {
        center.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.pendingNotifications = requests
            }
        }
    }

    // MARK: - Badge

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    func setBadge(count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
}

// MARK: - Notification Actions
extension NotificationService {
    func setupNotificationCategories() {
        // Define actions
        let openAction = UNNotificationAction(
            identifier: "OPEN_ACTION",
            title: "Open app",
            options: .foreground
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 1 uur",
            options: []
        )

        let doneAction = UNNotificationAction(
            identifier: "DONE_ACTION",
            title: "✓ Klaar!",
            options: .destructive
        )

        // Define category
        let category = UNNotificationCategory(
            identifier: "WERKGEHEUGEN_REMINDER",
            actions: [openAction, snoozeAction, doneAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }
}
