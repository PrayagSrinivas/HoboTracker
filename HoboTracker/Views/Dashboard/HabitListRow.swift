//
//  HabitListRow.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 14/03/26.
//

import SwiftUI

struct HabitListRow: View {
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
