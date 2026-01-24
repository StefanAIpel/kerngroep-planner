//
//  ContentView.swift
//  Werkgeheugen
//
//  Root view with tab navigation
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @EnvironmentObject var notificationService: NotificationService

    @State private var selectedTab = 0
    @State private var showCheckIn = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Nu", systemImage: "bolt.fill")
                    }
                    .tag(0)

                InboxView()
                    .tabItem {
                        Label("Inbox", systemImage: "tray.fill")
                    }
                    .tag(1)
                    .badge(taskStore.inboxTasks.count)

                CategoriesView()
                    .tabItem {
                        Label("Categorieën", systemImage: "square.grid.2x2.fill")
                    }
                    .tag(2)

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Label("Instellingen", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(.purple)

            // Confetti overlay
            if gamificationEngine.showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }

            // Points popup
            if gamificationEngine.showPointsPopup {
                PointsPopupView(points: gamificationEngine.lastPointsEarned)
                    .transition(.scale.combined(with: .opacity))
            }

            // Badge unlock popup
            if gamificationEngine.showBadgeUnlock, let badge = gamificationEngine.newBadge {
                BadgeUnlockView(badge: badge)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: gamificationEngine.showConfetti)
        .animation(.spring(response: 0.3), value: gamificationEngine.showPointsPopup)
        .animation(.spring(response: 0.3), value: gamificationEngine.showBadgeUnlock)
        .sheet(isPresented: $showCheckIn) {
            CheckInView()
        }
        .onAppear {
            setupApp()
        }
    }

    private func setupApp() {
        taskStore.setup(with: modelContext)
        gamificationEngine.setup(with: modelContext)

        Task {
            await notificationService.checkAuthorizationStatus()
            if !notificationService.isAuthorized {
                _ = await notificationService.requestPermission()
            }
            notificationService.setupNotificationCategories()
            notificationService.clearBadge()
        }
    }
}

// MARK: - Points Popup
struct PointsPopupView: View {
    let points: Int

    var body: some View {
        VStack {
            Spacer()

            Text("+\(points)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.yellow)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                .padding()
                .background(
                    Circle()
                        .fill(.purple.gradient)
                        .frame(width: 100, height: 100)
                )

            Spacer()
        }
    }
}

// MARK: - Badge Unlock
struct BadgeUnlockView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 12) {
                Text("🎉 Nieuwe badge!")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(badge.type.icon)
                    .font(.system(size: 64))

                Text(badge.type.title)
                    .font(.title2.bold())

                Text(badge.type.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 40)

            Spacer()
        }
        .background(Color.black.opacity(0.4))
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskStore())
        .environmentObject(GamificationEngine())
        .environmentObject(NotificationService())
}
