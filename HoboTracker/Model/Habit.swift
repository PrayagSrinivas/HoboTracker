//
//  Habit.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//


import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitDescription: String
    var iconName: String // SF Symbol name
    var colorHex: String 
    var loggedDates: [Date]
    var creationDate: Date
    
    init(name: String, habitDescription: String, iconName: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.habitDescription = habitDescription
        self.iconName = iconName
        self.colorHex = colorHex
        self.loggedDates = []
        self.creationDate = Date()
    }
    
    // Helper to check if logged today
    var isLoggedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return loggedDates.contains { Calendar.current.isDate($0, inSameDayAs: today) }
    }
}