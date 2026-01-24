//
//  StatsView.swift
//  Werkgeheugen
//
//  Points, levels, streaks, and badges
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @EnvironmentObject var taskStore: TaskStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Level card
                    LevelCard(
                        level: gamificationEngine.currentLevel,
                        points: gamificationEngine.totalPoints,
                        progress: gamificationEngine.levelProgress,
                        pointsToNext: gamificationEngine.pointsToNextLevel
                    )

                    // Streak card
                    StreakCard(
                        currentStreak: gamificationEngine.currentStreak,
                        hasCheckedInToday: gamificationEngine.hasCheckedInToday
                    )

                    // Stats grid
                    StatsGrid(stats: gamificationEngine.stats)

                    // Badges section
                    BadgesSection(badges: gamificationEngine.badges)

                    // Task stats
                    TaskStatsSection(tasks: taskStore.tasks)
                }
                .padding()
            }
            .navigationTitle("Stats")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Level Card
struct LevelCard: View {
    let level: Int
    let points: Int
    let progress: Double
    let pointsToNext: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(level)")
                        .font(.title.weight(.bold))
                    Text("\(points) punten")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Text("\(level)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                Text("Nog \(pointsToNext) punten tot level \(level + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let currentStreak: Int
    let hasCheckedInToday: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Flame icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)

                Text("🔥")
                    .font(.title)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentStreak) dagen streak")
                    .font(.headline)

                if hasCheckedInToday {
                    Text("✓ Vandaag ingecheckt!")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Check vandaag nog in!")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            // Streak visual
            HStack(spacing: 4) {
                ForEach(0..<min(currentStreak, 7), id: \.self) { _ in
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

// MARK: - Stats Grid
struct StatsGrid: View {
    let stats: UserStats?

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatBox(
                icon: "checkmark.circle.fill",
                value: "\(stats?.tasksCompleted ?? 0)",
                label: "Taken klaar",
                color: .green
            )

            StatBox(
                icon: "bolt.fill",
                value: "\(stats?.microStepsCompleted ?? 0)",
                label: "Microstappen",
                color: .yellow
            )

            StatBox(
                icon: "tray.fill",
                value: "\(stats?.inboxTriaged ?? 0)",
                label: "Inbox getriaged",
                color: .blue
            )

            StatBox(
                icon: "target",
                value: "\(stats?.focusSessionsCompleted ?? 0)",
                label: "Focus sessies",
                color: .purple
            )
        }
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.weight(.bold))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
        )
    }
}

// MARK: - Badges Section
struct BadgesSection: View {
    let badges: [Badge]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges")
                .font(.headline)

            if badges.isEmpty {
                HStack {
                    Image(systemName: "trophy")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("Nog geen badges verdiend")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(badges) { badge in
                        BadgeItem(badge: badge)
                    }
                }
            }

            // Locked badges preview
            Text("Te verdienen:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(BadgeType.allCases.filter { type in
                    !badges.contains(where: { $0.type == type })
                }.prefix(6), id: \.rawValue) { type in
                    LockedBadgeItem(type: type)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

struct BadgeItem: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 4) {
            Text(badge.type.icon)
                .font(.title)

            Text(badge.type.title)
                .font(.caption2)
                .lineLimit(1)

            if badge.isNew {
                Text("NIEUW")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.purple))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
    }
}

struct LockedBadgeItem: View {
    let type: BadgeType

    var body: some View {
        VStack(spacing: 4) {
            Text("🔒")
                .font(.title)
                .opacity(0.5)

            Text(type.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Task Stats Section
struct TaskStatsSection: View {
    let tasks: [WGTask]

    var categoryCounts: [(TaskCategory, Int)] {
        TaskCategory.allCases.map { category in
            (category, tasks.filter { $0.category == category && $0.status != .done }.count)
        }.filter { $0.1 > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Taken per categorie")
                .font(.headline)

            if categoryCounts.isEmpty {
                Text("Geen actieve taken")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(categoryCounts, id: \.0.rawValue) { category, count in
                    HStack {
                        Text(category.icon)
                        Text(category.label)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

#Preview {
    StatsView()
        .environmentObject(GamificationEngine())
        .environmentObject(TaskStore())
}
