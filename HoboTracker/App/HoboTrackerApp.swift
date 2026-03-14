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
    @StateObject private var appState = AppState()
    
    // Create a shared model container
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Habit.self)
            print("📦 HoboTrackerApp: ModelContainer created")
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(appState)
                .onOpenURL { url in
                    print("🔗 HoboTrackerApp: Received URL: \(url)")
                    print("🔗 HoboTrackerApp: URL scheme: \(url.scheme ?? "none")")
                    print("🔗 HoboTrackerApp: URL host: \(url.host ?? "none")")
                }
                .onAppear {
                    // Set the main context from the shared container
                    appState.setModelContext(modelContainer.mainContext)
                    print("📦 HoboTrackerApp: Set main context in AppState")
                }
        }
        .modelContainer(modelContainer)
    }
}
