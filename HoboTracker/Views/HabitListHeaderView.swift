//
//  HabitListHeaderView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 14/03/26.
//


import SwiftUI

struct HabitListHeaderView: View {
    
    // 1. Force the calendar to always start on Monday
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1 // 2 = Monday
        return cal
    }

    // 2. Calculate the 7 days of the current week
    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: interval.start)
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            
            // Bold Month Name (e.g., "March")
            Text(weekDates.first?.formatted(.dateTime.month(.wide)) ?? "")
                .font(.largeTitle.bold()) // Slightly larger since it's a main header
                .foregroundColor(.primary)
            
            // Monday to Sunday + Dates
            HStack(spacing: 6) { // ⚠️ This spacing (6) matches your row boxes
                ForEach(weekDates, id: \.self) { date in
                    let isToday = calendar.isDateInToday(date)
                    
                    VStack(spacing: 4) {
                        // Day Letter (M, T, W, T, F, S, S)
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 10, weight: isToday ? .heavy : .bold))
                        // Make the letter stand out a bit more if it's today
                            .foregroundColor(isToday ? .primary : .secondary)
                        // Date Number (14, 15, 16...)
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 12, weight: .bold))
                        // If today, make text white. Otherwise, standard text color.
                            .foregroundColor(isToday ? Color(UIColor.systemBackground) : .primary)                        // Force a square frame so the circle background looks perfect
                            .frame(width: 18, height: 18)
                            .background(isToday ? Color.primary : Color.clear)
                        // Add a solid background color if it is today
//                            .background(isToday ? Color.primary : Color.clear)
                        .clipShape(Circle())                    }
                    .frame(width: 18) // ⚠️ This width (18) matches your row boxes
                }
            }
        }
    }
}
#Preview {
    HabitListHeaderView()
        .padding(.horizontal) // Adds breathing room for the canvas preview
}
