//
//  YearCalendarView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 15/03/26.
//

import SwiftUI

struct YearCalendarView: View {
    let loggedDates: [Date]
    let color: Color
    
    private let calendar = Calendar.current
    private let today = Date()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
        let currentYear = calendar.component(.year, from: today)
        
        VStack(spacing: 16) {
            Text("\(currentYear)")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(1...12, id: \.self) { month in
                    VStack(spacing: 6) {
                        Text(monthName(for: month))
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        MiniMonthGridView(
                            month: month,
                            year: currentYear,
                            loggedDates: loggedDates,
                            color: color
                        )
                    }
                }
            }
        }
    }
    
    private func monthName(for month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        var components = DateComponents()
        components.month = month
        components.year = calendar.component(.year, from: today)
        if let date = calendar.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return ""
    }
}

// MARK: - Mini Month Grid View
struct MiniMonthGridView: View {
    let month: Int
    let year: Int
    let loggedDates: [Date]
    let color: Color
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    
    var body: some View {
        let daysInMonth = getDaysInMonth()
        let firstWeekday = getFirstWeekday()
        let loggedDays = getLoggedDaysInMonth()
        
        LazyVGrid(columns: columns, spacing: 2) {
            // Pad beginning
            ForEach(0..<firstWeekday, id: \.self) { _ in
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
            
            // Draw days
            ForEach(1...daysInMonth, id: \.self) { day in
                let isLogged = loggedDays.contains(day)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        isLogged
                        ? color.opacity(0.8)
                        : Color.gray.opacity(0.15)
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func getLoggedDaysInMonth() -> Set<Int> {
        let days = loggedDates.compactMap { date -> Int? in
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            if components.year == year, components.month == month {
                return components.day
            }
            return nil
        }
        return Set(days)
    }
    
    private func getDaysInMonth() -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
    
    private func getFirstWeekday() -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let firstDayOfMonth = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: firstDayOfMonth) - 1
    }
}
