//
//  MiniMonthCalendarView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//


import SwiftUI

struct MiniMonthCalendarView: View {
    let loggedDates: [Date]
    let color: Color
    
    private let calendar = Calendar.current
    private let today = Date()
    
    // 7 columns for Sunday -> Saturday
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortStandaloneWeekdaySymbols
    
    var body: some View {
        let daysInMonth = getDaysInMonth()
        let firstWeekday = getFirstWeekday()
        let loggedDays = loggedDaysThisMonth
        let currentDay = calendar.component(.day, from: today)
        
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                // 1. Pad the beginning of the grid so the 1st of the month falls on the correct weekday
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
                
                // 2. Draw the actual days
                ForEach(1...daysInMonth, id: \.self) { day in
                    let isLogged = loggedDays.contains(day)
                    let isToday = day == currentDay
                    
                    ZStack {
                        Circle()
                            .fill(
                                isLogged
                                ? LinearGradient(
                                    colors: [color.opacity(1.0), color.opacity(0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.22), Color.gray.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(isToday ? color.opacity(0.6) : Color.clear, lineWidth: 2)
                            )
                        
                        Text("\(day)")
                            .font(.caption2)
                            .foregroundColor(isLogged ? contrastTextColor(for: color) : .primary)
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    private func contrastTextColor(for background: Color) -> Color {
        let uiColor = UIColor(background)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let luminance = (0.299 * r) + (0.587 * g) + (0.114 * b)
            return luminance > 0.6 ? .black : .white
        }
        return .white
    }
}

// MARK: - Calendar Helpers
extension MiniMonthCalendarView {
    
    /// Converts the array of Date objects into a Set of Integers representing the logged days of the *current* month.
    /// This drastically improves rendering performance inside the LazyVGrid.
    private var loggedDaysThisMonth: Set<Int> {
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)
        
        let days = loggedDates.compactMap { date -> Int? in
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            if components.year == currentYear, components.month == currentMonth {
                return components.day
            }
            return nil
        }
        return Set(days)
    }
    
    /// Returns the total number of days in the current month (e.g., 28, 30, 31)
    private func getDaysInMonth() -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: today) else {
            return 30 // Fallback
        }
        return range.count
    }
    
    /// Returns the weekday index of the 1st of the month to determine how many empty cells to draw.
    /// Sunday = 0, Monday = 1, etc.
    private func getFirstWeekday() -> Int {
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let firstDayOfMonth = calendar.date(from: components) else { return 0 }
        
        // calendar.component(.weekday, ...) returns 1 for Sunday, 2 for Monday.
        // Subtracting 1 gives us a 0-indexed offset perfect for our empty `ForEach` loop.
        return calendar.component(.weekday, from: firstDayOfMonth) - 1
    }
}
