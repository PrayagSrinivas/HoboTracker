//
//  HabitDetailView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//


import Charts
import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @StateObject private var viewModel: HabitDetailViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    init(habit: Habit) {
        _viewModel = StateObject(wrappedValue: HabitDetailViewModel(habit: habit))
    }
    
    var body: some View {
        Group {
            if isDeleting {
                // Show empty view while deleting to prevent accessing deleted habit
                Color.clear
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        // Conditionally show view based on viewMode
                        switch viewModel.viewMode {
                        case .week:
                            weeklySummaryCard
                        case .month:
                            monthCalendarCard
                        case .year:
                            yearCalendarCard
                        }
                        
                        if viewModel.habit.loggedDates.isEmpty {
                            emptyState
                        } else {
                            chartSection
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(isDeleting ? "Deleting..." : viewModel.habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isDeleting {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Menu {
                            Picker("Duration", selection: $viewModel.viewMode) {
                                ForEach(ViewMode.allCases, id: \.self) { mode in
                                    Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.viewMode.iconName)
                                Text(viewModel.viewMode.rawValue)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.primary)
                        }
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .confirmationDialog("Delete Habit", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(viewModel.habit.name)'? This action cannot be undone.")
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private func deleteHabit() {
        let habitName = viewModel.habit.name
        let habitToDelete = viewModel.habit
        
        print("🗑️ HabitDetailView: User confirmed deletion of '\(habitName)'")
        
        // Set isDeleting FIRST to prevent view from accessing habit properties
        isDeleting = true
        
        // Give SwiftUI a moment to re-render with empty view
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            
            // Now safe to delete
            habitToDelete.isDeleted = true
            habitToDelete.updatedAt = Date()
            habitToDelete.syncStatus = "pending"
            
            // Save to mark as deleted
            try? context.save()
            
            // Delete from local database
            context.delete(habitToDelete)
            try? context.save()
            
            print("✅ HabitDetailView: Habit deleted locally")
            
            // Dismiss the view
            dismiss()
            
            // Trigger sync in background
            await appState.syncWithContext(context)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.habit.iconName)
                .font(.system(size: 28))
                .foregroundColor(viewModel.habitColor)
                .frame(width: 44, height: 44)
                .background(viewModel.habitColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.habit.name)
                    .font(.title3.bold())
                if !viewModel.habit.habitDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(viewModel.habit.habitDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            monthProgressRing
        }
    }
    
    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Streak: \(viewModel.weekLoggedCount) Days")
                .font(.subheadline.bold())

            HStack(spacing: 8) {
                ForEach(Array(viewModel.currentWeekDates.enumerated()), id: \.offset) { index, date in
                    let isLogged = viewModel.loggedDaysSet.contains(viewModel.calendar.startOfDay(for: date))
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                isLogged
                                ? LinearGradient(
                                    colors: [viewModel.habitColor.opacity(1.0), viewModel.habitColor.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.22), Color.gray.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 28)

                        Text(viewModel.shortWeekdaySymbol(for: index))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
    
    private var monthCalendarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                Text(Date().formatted(.dateTime.month(.wide)))
                    .font(.subheadline.bold())
                Text("\(viewModel.monthLoggedCount)/\(viewModel.monthTotalDays) Days")
                    .font(.subheadline.bold())
                    .foregroundColor(viewModel.habitColor)
            }
            
            VStack(spacing: 4) {
                ForEach(viewModel.weeksInCurrentMonth, id: \.weekNumber) { week in
                    ModernWeekRow(
                        week: week,
                        loggedDaysSet: viewModel.loggedDaysSet,
                        color: viewModel.habitColor,
                        calendar: viewModel.calendar
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
    
    private var yearCalendarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            YearCalendarView(
                loggedDates: viewModel.habit.loggedDates,
                color: viewModel.habitColor
            )
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var monthProgressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    LinearGradient(
                        colors: [viewModel.habitColor, viewModel.habitColor.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(viewModel.progressCount)/\(viewModel.progressTotal)")
                    .font(.caption.bold())
                Text("Days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 58, height: 58)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.chartMode == .daily ? "Daily Logs" : "Weekly Totals")
                        .font(.headline)
                    Spacer()
                    Picker("Chart Mode", selection: $viewModel.chartMode) {
                        Text("Daily").tag(ChartMode.daily)
                        Text("Weekly").tag(ChartMode.weekly)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }

                HStack {
                    Text(viewModel.chartMode == .daily ? viewModel.dailyRange.title : viewModel.weeklyRange.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if viewModel.chartMode == .daily {
                        Picker("Daily Range", selection: $viewModel.dailyRange) {
                            ForEach(DailyRange.allCases, id: \.self) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Picker("Weekly Range", selection: $viewModel.weeklyRange) {
                            ForEach(WeeklyRange.allCases, id: \.self) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }

            if viewModel.chartMode == .daily {
                Chart(viewModel.dailyLogs) { day in
                    BarMark(
                        x: .value("Date", day.date),
                        y: .value("Logged", day.isLogged ? 1 : 0)
                    )
                    .foregroundStyle(day.isLogged ? viewModel.habitColor : Color.gray.opacity(0.2))
                    .cornerRadius(2)
                }
                .chartYScale(domain: 0...1)
                .chartYAxis(.hidden)
                .frame(height: 160)
            } else {
                Chart {
                    ForEach(viewModel.weeklyLogs) { week in
                        BarMark(
                            x: .value("Week", week.weekStart),
                            y: .value("Total", week.totalLogged)
                        )
                        .foregroundStyle(viewModel.habitColor.opacity(0.25))
                        .cornerRadius(3)

                        LineMark(
                            x: .value("Week", week.weekStart),
                            y: .value("Total", week.totalLogged)
                        )
                        .foregroundStyle(viewModel.habitColor)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Every expert was once a beginner.")
                .font(.title3.bold())
            Text("Log your first day to start building momentum!")
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
}
