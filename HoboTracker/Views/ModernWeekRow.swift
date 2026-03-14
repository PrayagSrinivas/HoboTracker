//
//  ModernWeekRow.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 15/03/26.
//

import SwiftUI

struct ModernWeekRow: View {
    let week: WeekInMonth
    let loggedDaysSet: Set<Date>
    let color: Color
    let calendar: Calendar
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(week.days, id: \.self) { date in
                let isLogged = loggedDaysSet.contains(calendar.startOfDay(for: date))
                let dayNumber = calendar.component(.day, from: date)
                let isCurrentMonth = calendar.component(.month, from: date) == week.month
                
                VStack(spacing: 2) {
                    if isCurrentMonth {
                        // Only draw the box and text if it's the current month
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                isLogged
                                ? LinearGradient(
                                    colors: [color.opacity(1.0), color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 20)
                            .overlay {
                                Text("\(dayNumber)")
                                    .font(.caption2.bold())
                                    .foregroundColor(isLogged ? .white : .primary)
                            }
                    } else {
                        // Keep the empty space for alignment, but don't show the date
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
}
