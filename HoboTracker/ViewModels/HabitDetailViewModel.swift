import Combine
import SwiftUI

@MainActor
final class HabitDetailViewModel: ObservableObject {
    let habit: Habit
    let calendar = Calendar.current
    let today = Date()

    @Published var chartMode: ChartMode = .daily
    @Published var dailyRange: DailyRange = .days30
    @Published var weeklyRange: WeeklyRange = .weeks12
    @Published var viewMode: ViewMode = .week

    init(habit: Habit) {
        self.habit = habit
    }

    var habitColor: Color {
        color(from: habit.colorHex)
    }

    var normalizedLoggedDays: [Date] {
        let uniqueDays = Set(habit.loggedDates.map { calendar.startOfDay(for: $0) })
        return uniqueDays.sorted()
    }

    var loggedDaysSet: Set<Date> {
        Set(normalizedLoggedDays)
    }

    var currentWeekDates: [Date] {
        let todayStart = calendar.startOfDay(for: today)
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: todayStart) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: interval.start)
        }
    }

    var weekLoggedCount: Int {
        currentWeekDates.filter { loggedDaysSet.contains(calendar.startOfDay(for: $0)) }.count
    }

    var monthLoggedCount: Int {
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from: today)
        return normalizedLoggedDays.filter {
            let components = calendar.dateComponents([.year, .month], from: $0)
            return components.year == year && components.month == month
        }.count
    }

    var monthTotalDays: Int {
        calendar.range(of: .day, in: .month, for: today)?.count ?? 30
    }
    
    var yearLoggedCount: Int {
        let year = calendar.component(.year, from: today)
        return normalizedLoggedDays.filter {
            let components = calendar.dateComponents([.year], from: $0)
            return components.year == year
        }.count
    }
    
    var yearTotalDays: Int {
        let year = calendar.component(.year, from: today)
        let isLeapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)
        return isLeapYear ? 366 : 365
    }

    // Dynamic progress based on view mode
    var progressCount: Int {
        switch viewMode {
        case .week:
            return weekLoggedCount
        case .month:
            return monthLoggedCount
        case .year:
            return yearLoggedCount
        }
    }
    
    var progressTotal: Int {
        switch viewMode {
        case .week:
            return 7
        case .month:
            return monthTotalDays
        case .year:
            return yearTotalDays
        }
    }
    
    var progress: Double {
        guard progressTotal > 0 else { return 0 }
        return Double(progressCount) / Double(progressTotal)
    }

    var monthProgress: Double {
        guard monthTotalDays > 0 else { return 0 }
        return Double(monthLoggedCount) / Double(monthTotalDays)
    }
    
    var weeksInCurrentMonth: [WeekInMonth] {
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)
        
        // Get first day of month
        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
        components.day = 1
        
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }
        
        // Get the start of the week containing the first day of the month
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: firstDayOfMonth)?.start else { return [] }
        
        var weeks: [WeekInMonth] = []
        var currentWeekStart = weekStart
        var weekNumber = 0
        
        // Generate weeks until we've covered the entire month
        while true {
            var days: [Date] = []
            for dayOffset in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) {
                    days.append(day)
                }
            }
            
            // Check if this week contains any days from the current month
            let hasCurrentMonthDays = days.contains { date in
                let month = calendar.component(.month, from: date)
                return month == currentMonth
            }
            
            if hasCurrentMonthDays {
                weeks.append(WeekInMonth(weekNumber: weekNumber, month: currentMonth, days: days))
                weekNumber += 1
            }
            
            // Move to next week
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else { break }
            currentWeekStart = nextWeek
            
            // Check if we've moved past the current month
            let nextWeekMonth = calendar.component(.month, from: currentWeekStart)
            if nextWeekMonth != currentMonth && !hasCurrentMonthDays {
                break
            }
            
            // Safety check: don't generate more than 6 weeks
            if weekNumber >= 6 {
                break
            }
        }
        
        return weeks
    }

    var dailyLogs: [DayLog] {
        let todayStart = calendar.startOfDay(for: today)
        let range = dailyRange.value
        return (0..<range).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(range - 1) + offset, to: todayStart) else { return nil }
            return DayLog(date: date, isLogged: loggedDaysSet.contains(date))
        }
    }

    var weeklyLogs: [WeekLog] {
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

    func shortWeekdaySymbol(for index: Int) -> String {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = calendar.firstWeekday - 1
        let ordered = Array(symbols[startIndex...] + symbols[..<startIndex])
        return ordered.indices.contains(index) ? ordered[index] : symbols[index % symbols.count]
    }

    func color(from hex: String) -> Color {
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

struct DayLog: Identifiable {
    let date: Date
    let isLogged: Bool
    var id: Date { date }
}

struct WeekLog: Identifiable {
    let weekStart: Date
    let totalLogged: Int
    var id: Date { weekStart }
}

enum ChartMode: String, CaseIterable {
    case daily
    case weekly
}

enum DailyRange: Int, CaseIterable {
    case days30 = 30
    case days45 = 45
    case days60 = 60
    case days90 = 90

    var value: Int { rawValue }

    var title: String {
        "\(rawValue) days"
    }
}

enum WeeklyRange: Int, CaseIterable {
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

enum ViewMode: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var iconName: String {
        switch self {
        case .week:
            return "calendar.badge.clock"
        case .month:
            return "calendar"
        case .year:
            return "calendar.badge.checkmark"
        }
    }
}

struct WeekInMonth: Identifiable {
    let weekNumber: Int
    let month: Int
    let days: [Date]
    
    var id: Int { weekNumber }
}
