//
//  DashboardView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Habit.creationDate, order: .forward) private var habits: [Habit]
    @Environment(\.modelContext) private var context
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(habits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit)) {
                            HabitCell(habit: habit) {
                                toggleHabit(habit)
                            }
                        }
                        .buttonStyle(.plain) // Prevents the NavigationLink from hijacking the checkbox tap
                    }
                }
                .padding()
            }
            .navigationTitle("My Activity")
        }
    }
    
    private func toggleHabit(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: Date())
        if habit.isLoggedToday {
            habit.loggedDates.removeAll { Calendar.current.isDate($0, inSameDayAs: today) }
        } else {
            habit.loggedDates.append(today)
        }
        try? context.save()
    }
}
