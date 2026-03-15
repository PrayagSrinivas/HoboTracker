//
//  ExampleHabitsView.swift
//  HoboTracker
//
//  Created by Codex on 13/03/26.
//

import SwiftUI

struct ExampleHabitsView: View {
    private let exampleHabits: [Habit] = ExampleHabitsView.makeHabits()
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(exampleHabits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit)) {
                            HabitCell(habit: habit) {
                                // Mock data is read-only
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Examples")
        }
    }

    private static func makeHabits() -> [Habit] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func generateLoggedDates(daysBack: Int, rule: (Date, Int) -> Bool) -> [Date] {
            var dates: [Date] = []
            for offset in 0..<daysBack {
                guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
                if rule(date, offset) {
                    dates.append(date)
                }
            }
            return dates
        }

        func makeHabit(
            name: String,
            description: String,
            iconName: String,
            colorHex: String,
            daysBack: Int,
            rule: @escaping (Date, Int) -> Bool
        ) -> Habit {
            let habit = Habit(name: name, habitDescription: description, iconName: iconName, colorHex: colorHex)
            habit.creationDate = calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today
            habit.loggedDates = generateLoggedDates(daysBack: daysBack, rule: rule)
            return habit
        }

        return [
            makeHabit(
                name: "Running",
                description: "Daily runs with a long recent streak.",
                iconName: "figure.run",
                colorHex: "#FF3B30",
                daysBack: 180,
                rule: { _, offset in
                    if offset < 24 { return true }
                    return offset % 2 == 0
                }
            ),
            makeHabit(
                name: "Cycling",
                description: "Weekdays only, steady habit.",
                iconName: "bicycle",
                colorHex: "#34C759",
                daysBack: 120,
                rule: { date, _ in
                    !calendar.isDateInWeekend(date)
                }
            ),
            makeHabit(
                name: "Reading",
                description: "Mon, Wed, Fri pattern.",
                iconName: "book.fill",
                colorHex: "#007AFF",
                daysBack: 90,
                rule: { date, _ in
                    let weekday = calendar.component(.weekday, from: date)
                    return weekday == 2 || weekday == 4 || weekday == 6
                }
            ),
            makeHabit(
                name: "Meditation",
                description: "Inconsistent logging with gaps.",
                iconName: "brain.head.profile",
                colorHex: "#AF52DE",
                daysBack: 150,
                rule: { _, offset in
                    offset % 5 == 0 || offset % 9 == 0
                }
            ),
            makeHabit(
                name: "Hydration",
                description: "Mostly consistent, a few missed days.",
                iconName: "drop.fill",
                colorHex: "#5AC8FA",
                daysBack: 75,
                rule: { _, offset in
                    offset % 7 != 0
                }
            ),
            makeHabit(
                name: "Journaling",
                description: "New habit with sparse logs.",
                iconName: "pencil",
                colorHex: "#FF9500",
                daysBack: 45,
                rule: { _, offset in
                    offset % 6 == 0
                }
            )
        ]
    }
}
