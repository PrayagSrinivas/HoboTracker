//
//  DashboardView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Habit.creationDate, order: .forward) private var allHabits: [Habit]
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    // Filter habits to show only current user's habits
    private var habits: [Habit] {
        guard let currentUserId = appState.authService.userId else {
            print("⚠️ DashboardView: No current user ID, showing all habits")
            return allHabits
        }
        let filtered = allHabits.filter { habit in
            // Case-insensitive comparison for UUID matching
            let habitOwnerId = habit.ownerId?.lowercased()
            return habitOwnerId == currentUserId.lowercased() || habit.ownerId == nil
        }
        print("📊 DashboardView: Showing \(filtered.count) habits for user \(currentUserId)")
        return filtered
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isGridLayout {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(habits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                HabitCell(habit: habit) {
                                    viewModel.toggleHabit(habit, context: context, userId: appState.authService.userId)
                                    Task { @MainActor in
                                        await appState.syncWithContext(context)
                                    }
                                }
                            }
                            .buttonStyle(.plain) // Prevents the NavigationLink from hijacking the checkbox tap
                        }
                    }
                    .padding()
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(habits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                HabitListRow(habit: habit, color: viewModel.color(from: habit.colorHex)) {
                                    viewModel.toggleHabit(habit, context: context, userId: appState.authService.userId)
                                    Task { @MainActor in
                                        await appState.syncWithContext(context)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleLayout()
                    } label: {
                        Image(systemName: viewModel.isGridLayout ? "list.bullet" : "square.grid.2x2")
                    }
                    .accessibilityLabel(viewModel.isGridLayout ? "Switch to List" : "Switch to Grid")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isShowingCreateHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Create Habit")
                }
            }
            .navigationDestination(isPresented: $viewModel.isShowingCreateHabit) {
                CreateHabitView()
                    .navigationTitle("Create Habit")
            }
        }
    }
}

private struct HabitListRow: View {
    let habit: Habit
    let color: Color
    let onToggle: () -> Void
    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: interval.start)
        }
    }

    private var loggedDaysSet: Set<Date> {
        Set(habit.loggedDates.map { calendar.startOfDay(for: $0) })
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: habit.iconName)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name)
                    .font(.headline)

                HStack(spacing: 6) {
                    ForEach(weekDates, id: \.self) { date in
                        let isLogged = loggedDaysSet.contains(calendar.startOfDay(for: date))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                isLogged
                                ? LinearGradient(
                                    colors: [color.opacity(1.0), color.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.22), Color.gray.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 18, height: 12)
                    }
                }
            }

            Spacer()

            Button(action: onToggle) {
                Image(systemName: habit.isLoggedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(habit.isLoggedToday ? color : .gray)
                    .font(.title3)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
