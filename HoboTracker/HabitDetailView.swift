//
//  HabitDetailView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//


import Charts
import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    private let calendar = Calendar.current
    private let today = Date()
    @State private var chartMode: ChartMode = .daily
    @State private var dailyRange: DailyRange = .days30
    @State private var weeklyRange: WeeklyRange = .weeks12
    
    private var habitColor: Color {
        color(from: habit.colorHex)
    }
    
    private var normalizedLoggedDays: [Date] {
        let uniqueDays = Set(habit.loggedDates.map { calendar.startOfDay(for: $0) })
        return uniqueDays.sorted()
    }
    
    private var loggedDaysSet: Set<Date> {
        Set(normalizedLoggedDays)
    }
    
    private var currentStreak: Int {
        let todayStart = calendar.startOfDay(for: today)
        guard loggedDaysSet.contains(todayStart) else { return 0 }
        
        var streak = 0
        var date = todayStart
        while loggedDaysSet.contains(date) {
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDate
        }
        return streak
    }
    
    private var maxStreak: Int {
        guard normalizedLoggedDays.count > 1 else { return normalizedLoggedDays.count }
        
        var maxCount = 1
        var currentCount = 1
        
        for index in 1..<normalizedLoggedDays.count {
            let previous = normalizedLoggedDays[index - 1]
            let current = normalizedLoggedDays[index]
            let delta = calendar.dateComponents([.day], from: previous, to: current).day ?? 0
            if delta == 1 {
                currentCount += 1
            } else {
                maxCount = max(maxCount, currentCount)
                currentCount = 1
            }
        }
        
        return max(maxCount, currentCount)
    }
    
    private var daysSinceLastLog: Int {
        let todayStart = calendar.startOfDay(for: today)
        if let lastLog = normalizedLoggedDays.last {
            return calendar.dateComponents([.day], from: lastLog, to: todayStart).day ?? 0
        }
        return calendar.dateComponents([.day], from: habit.creationDate, to: todayStart).day ?? 0
    }
    
    private var dailyLogs: [DayLog] {
        let todayStart = calendar.startOfDay(for: today)
        let range = dailyRange.value
        return (0..<range).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(range - 1) + offset, to: todayStart) else { return nil }
            return DayLog(date: date, isLogged: loggedDaysSet.contains(date))
        }
    }

    private var weeklyLogs: [WeekLog] {
        let todayStart = calendar.startOfDay(for: today)
        let range = weeklyRange.value
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -(range - 1), to: todayStart) else { return [] }
        let startOfFirstWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)) ?? startDate

        return (0..<range).compactMap { offset in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: startOfFirstWeek) else { return nil }
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let count = normalizedLoggedDays.filter { $0 >= weekStart && $0 < weekEnd }.count
            return WeekLog(weekStart: weekStart, totalLogged: count)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsSection
                
                if habit.loggedDates.isEmpty {
                    emptyState
                } else {
                    chartSection
                }
            }
            .padding()
        }
        .navigationTitle(habit.name)
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.iconName)
                .font(.system(size: 28))
                .foregroundColor(habitColor)
                .frame(width: 44, height: 44)
                .background(habitColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.title3.bold())
                if !habit.habitDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(habit.habitDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(title: "Current Streak", value: "\(currentStreak) days")
                statCard(title: "Max Streak", value: "\(maxStreak) days")
            }
            HStack(spacing: 12) {
                statCard(title: "Days Since Last Log", value: "\(daysSinceLastLog)")
                statCard(title: "Total Logged", value: "\(normalizedLoggedDays.count)")
            }
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(chartMode == .daily ? "Daily Logs" : "Weekly Totals")
                        .font(.headline)
                    Spacer()
                    Picker("Chart Mode", selection: $chartMode) {
                        Text("Daily").tag(ChartMode.daily)
                        Text("Weekly").tag(ChartMode.weekly)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }

                HStack {
                    Text(chartMode == .daily ? dailyRange.title : weeklyRange.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if chartMode == .daily {
                        Picker("Daily Range", selection: $dailyRange) {
                            ForEach(DailyRange.allCases, id: \.self) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Picker("Weekly Range", selection: $weeklyRange) {
                            ForEach(WeeklyRange.allCases, id: \.self) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }

            if chartMode == .daily {
                Chart(dailyLogs) { day in
                    BarMark(
                        x: .value("Date", day.date),
                        y: .value("Logged", day.isLogged ? 1 : 0)
                    )
                    .foregroundStyle(day.isLogged ? habitColor : Color.gray.opacity(0.2))
                    .cornerRadius(2)
                }
                .chartYScale(domain: 0...1)
                .chartYAxis(.hidden)
                .frame(height: 160)
            } else {
                Chart {
                    ForEach(weeklyLogs) { week in
                        BarMark(
                            x: .value("Week", week.weekStart),
                            y: .value("Total", week.totalLogged)
                        )
                        .foregroundStyle(habitColor.opacity(0.25))
                        .cornerRadius(3)

                        LineMark(
                            x: .value("Week", week.weekStart),
                            y: .value("Total", week.totalLogged)
                        )
                        .foregroundStyle(habitColor)
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
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
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
    
    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func color(from hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
private struct DayLog: Identifiable {
    let date: Date
    let isLogged: Bool
    var id: Date { date }
}

private struct WeekLog: Identifiable {
    let weekStart: Date
    let totalLogged: Int
    var id: Date { weekStart }
}
private enum ChartMode: String, CaseIterable {
    case daily
    case weekly
}

private enum DailyRange: Int, CaseIterable {
    case days30 = 30
    case days45 = 45
    case days60 = 60
    case days90 = 90
    var value: Int { rawValue }

    var title: String {
        "\(rawValue) days"
    }
}

private enum WeeklyRange: Int, CaseIterable {
    case weeks3 = 3
    case weeks6 = 6
    case weeks12 = 12
    case weeks26 = 26
    case weeks52 = 52

    var value: Int { rawValue }

    var title: String {
        "\(rawValue) weeks"
    }
}

