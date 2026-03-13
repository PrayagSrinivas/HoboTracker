//
//  HoboTrackerApp.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//


import SwiftUI
import SwiftData

@main
struct HoboTracker: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Activity", systemImage: "square.grid.2x2")
                    }
                
                ExampleHabitsView()
                    .tabItem {
                        Label("Examples", systemImage: "sparkles")
                    }
            }
        }
        .modelContainer(for: Habit.self)
    }
}
