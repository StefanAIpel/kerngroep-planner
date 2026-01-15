//
//  WerkgeheugenApp.swift
//  Werkgeheugen
//
//  ADHD-friendly task app - "Eerst dumpen, dan pas organiseren"
//

import SwiftUI
import SwiftData

@main
struct WerkgeheugenApp: App {
    let modelContainer: ModelContainer

    @StateObject private var taskStore = TaskStore()
    @StateObject private var gamificationEngine = GamificationEngine()
    @StateObject private var notificationService = NotificationService()

    init() {
        do {
            let schema = Schema([
                WGTask.self,
                UserStats.self,
                Badge.self,
                UserSettings.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskStore)
                .environmentObject(gamificationEngine)
                .environmentObject(notificationService)
        }
        .modelContainer(modelContainer)
    }
}
