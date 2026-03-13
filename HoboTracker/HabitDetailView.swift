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

    private var currentWeekDates: [Date] {
        let todayStart = calendar.startOfDay(for: today)
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: todayStart) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: interval.start)
        }
    }

    private var weekLoggedCount: Int {
        currentWeekDates.filter { loggedDaysSet.contains(calendar.startOfDay(for: $0)) }.count
    }

    private var monthLoggedCount: Int {
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from: today)
        return normalizedLoggedDays.filter {
            let components = calendar.dateComponents([.year, .month], from: $0)
            return components.year == year && components.month == month
        }.count
    }

    private var monthTotalDays: Int {
        calendar.range(of: .day, in: .month, for: today)?.count ?? 30
    }

    private var monthProgress: Double {
        guard monthTotalDays > 0 else { return 0 }
        return Double(monthLoggedCount) / Double(monthTotalDays)
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
                weeklySummaryCard
                
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
            monthProgressRing
        }
    }
    
    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Streak: \(weekLoggedCount) Days")
                .font(.subheadline.bold())

            HStack(spacing: 8) {
                ForEach(Array(currentWeekDates.enumerated()), id: \.offset) { index, date in
                    let isLogged = loggedDaysSet.contains(calendar.startOfDay(for: date))
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                isLogged
                                ? LinearGradient(
                                    colors: [habitColor.opacity(1.0), habitColor.opacity(0.65)],
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

                        Text(shortWeekdaySymbol(for: index))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var monthProgressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: monthProgress)
                .stroke(
                    LinearGradient(
                        colors: [habitColor, habitColor.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(monthLoggedCount)/\(monthTotalDays)")
                    .font(.caption.bold())
                Text("Days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 58, height: 58)
    }

    private func shortWeekdaySymbol(for index: Int) -> String {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = calendar.firstWeekday - 1
        let ordered = Array(symbols[startIndex...] + symbols[..<startIndex])
        return ordered.indices.contains(index) ? ordered[index] : symbols[index % symbols.count]
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
