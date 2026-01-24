//
//  UserSettings.swift
//  Werkgeheugen
//
//  User preferences and notification settings
//

import Foundation
import SwiftData

// MARK: - Notification Strictness
enum NotificationStrictness: String, Codable, CaseIterable {
    case zacht = "zacht"       // Gentle reminders
    case normaal = "normaal"   // Standard
    case streng = "streng"     // More persistent

    var label: String {
        switch self {
        case .zacht: return "Zacht 🌸"
        case .normaal: return "Normaal 📱"
        case .streng: return "Streng 💪"
        }
    }

    var description: String {
        switch self {
        case .zacht: return "Vriendelijke herinneringen, minder vaak"
        case .normaal: return "Standaard notificaties"
        case .streng: return "Meer herinneringen, iets dringender toon"
        }
    }
}

// MARK: - UserSettings Model (SwiftData)
@Model
final class UserSettings {
    var id: UUID

    // Notification times (stored as minutes from midnight)
    var morningNotificationTime: Int  // e.g., 510 = 08:30
    var middayNotificationTime: Int   // e.g., 780 = 13:00
    var eveningNotificationTime: Int  // e.g., 1290 = 21:30

    var notificationsEnabled: Bool
    var morningEnabled: Bool
    var middayEnabled: Bool
    var eveningEnabled: Bool

    var strictnessRaw: String

    // Feature toggles
    var hapticsEnabled: Bool
    var confettiEnabled: Bool
    var soundsEnabled: Bool
    var mascotEnabled: Bool

    // Custom categories (JSON encoded)
    var customCategoriesJSON: String

    var createdAt: Date
    var updatedAt: Date

    var strictness: NotificationStrictness {
        get { NotificationStrictness(rawValue: strictnessRaw) ?? .normaal }
        set { strictnessRaw = newValue.rawValue }
    }

    init() {
        self.id = UUID()
        self.morningNotificationTime = 510   // 08:30
        self.middayNotificationTime = 780    // 13:00
        self.eveningNotificationTime = 1290  // 21:30
        self.notificationsEnabled = true
        self.morningEnabled = true
        self.middayEnabled = true
        self.eveningEnabled = true
        self.strictnessRaw = NotificationStrictness.normaal.rawValue
        self.hapticsEnabled = true
        self.confettiEnabled = true
        self.soundsEnabled = true
        self.mascotEnabled = true
        self.customCategoriesJSON = "[]"
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Time Helpers

    var morningTime: Date {
        get { timeFromMinutes(morningNotificationTime) }
        set { morningNotificationTime = minutesFromTime(newValue) }
    }

    var middayTime: Date {
        get { timeFromMinutes(middayNotificationTime) }
        set { middayNotificationTime = minutesFromTime(newValue) }
    }

    var eveningTime: Date {
        get { timeFromMinutes(eveningNotificationTime) }
        set { eveningNotificationTime = minutesFromTime(newValue) }
    }

    private func timeFromMinutes(_ minutes: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .minute, value: minutes, to: today) ?? today
    }

    private func minutesFromTime(_ time: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    func formattedTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }

    var morningTimeFormatted: String { formattedTime(morningNotificationTime) }
    var middayTimeFormatted: String { formattedTime(middayNotificationTime) }
    var eveningTimeFormatted: String { formattedTime(eveningNotificationTime) }

    // MARK: - Custom Categories

    var customCategories: [String] {
        get {
            guard let data = customCategoriesJSON.data(using: .utf8),
                  let categories = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return categories
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                customCategoriesJSON = json
                updatedAt = Date()
            }
        }
    }

    func addCustomCategory(_ name: String) {
        var categories = customCategories
        if !categories.contains(name) {
            categories.append(name)
            customCategories = categories
        }
    }

    func removeCustomCategory(_ name: String) {
        var categories = customCategories
        categories.removeAll { $0 == name }
        customCategories = categories
    }
}

// MARK: - Default Notification Messages
struct NotificationMessages {
    static func morning(strictness: NotificationStrictness) -> String {
        switch strictness {
        case .zacht: return "Goeiemorgen! Zin in een microstapje? 🌱"
        case .normaal: return "Goeiemorgen! 3 microstappen voor vandaag? ☀️"
        case .streng: return "Goeiemorgen! Tijd om te starten. 3 microstappen wachten! 💪"
        }
    }

    static func midday(strictness: NotificationStrictness) -> String {
        switch strictness {
        case .zacht: return "Hé, zin in een quick win? 🎯"
        case .normaal: return "Even 1 quick win pakken? 💪"
        case .streng: return "Halverwege de dag! Pak nu die quick win! 🔥"
        }
    }

    static func evening(strictness: NotificationStrictness) -> String {
        switch strictness {
        case .zacht: return "Tijd voor rust. Even terugkijken? 🌙"
        case .normaal: return "Check-in tijd! Wat is gelukt vandaag? 🌟"
        case .streng: return "Avond check-in! Laten we even terugkijken en morgen plannen. ✨"
        }
    }
}
