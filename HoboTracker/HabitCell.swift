//
//  HabitCell.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//

import SwiftUI

struct HabitCell: View {
    let habit: Habit
    let onToggle: () -> Void

    private var habitColor: Color {
        color(from: habit.colorHex)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: habit.iconName)
                    .foregroundColor(habitColor)
                Text(habit.name)
                    .font(.headline)
                Spacer()
            }
            
            // Mini Calendar
            MiniMonthCalendarView(loggedDates: habit.loggedDates, color: habitColor)
                .frame(minHeight: 96)
            
            Divider()
            
            // Quick Log Button
            Button(action: onToggle) {
                HStack {
                    Image(systemName: habit.isLoggedToday ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(habit.isLoggedToday ? habitColor : .gray)
                    Text(habit.isLoggedToday ? "Completed" : "Log Today")
                        .font(habit.isLoggedToday ? .caption.bold() : .caption)
                        .foregroundColor(habit.isLoggedToday ? .primary : .secondary)
                    Spacer()
                }
            }
            .buttonStyle(.borderless) 
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
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
