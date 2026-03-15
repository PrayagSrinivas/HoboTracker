//
//  DashboardView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Habit.creationDate, order: .forward) private var allHabits: [Habit]
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    @State private var searchText = ""
    
    // Filter habits to show only current user's habits
    private var userHabits: [Habit] {
        guard let currentUserId = appState.authService.userId else {
            print("⚠️ DashboardView: No current user ID, showing all habits")
            return allHabits
        }
        let filtered = allHabits.filter { habit in
            // Case-insensitive comparison for UUID matching
            let habitOwnerId = habit.ownerId?.lowercased()
            return habitOwnerId == currentUserId.lowercased() || habit.ownerId == nil
        }
        print("📊 DashboardView: Showing \(filtered.count) habits for user \(currentUserId)")
        return filtered
    }
    
    // Filter by search text
    private var habits: [Habit] {
        if searchText.isEmpty {
            return userHabits
        } else {
            return userHabits.filter { habit in
                habit.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HabitListHeaderView()
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                List {
                    ForEach(habits) { habit in
                        // 1. The visible custom row
                        HabitListRow(habit: habit, color: viewModel.color(from: habit.colorHex)) {
                            viewModel.toggleHabit(habit, context: context, userId: appState.authService.userId)
                            Task { @MainActor in
                                await appState.syncWithContext(context)
                            }
                        }
                        // 2. The hidden NavigationLink hack
                        .background(
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                EmptyView()
                            }
                                .opacity(0)
                        )
                        // 3. Row Styling & Swipe Actions
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isShowingCreateHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Create Habit")
                }
            }
            .searchable(text: $searchText, prompt: "Search habits")
            .navigationDestination(isPresented: $viewModel.isShowingCreateHabit) {
                CreateHabitView()
                    .navigationTitle("Create Habit")
            }
        }
    }
    
    private func deleteHabit(_ habit: Habit) {
        print("🗑️ DashboardView: Deleting habit '\(habit.name)'")
        
        // Mark as deleted and sync
        habit.isDeleted = true
        habit.updatedAt = Date()
        habit.syncStatus = "pending"
        
        // Save to mark as deleted
        try? context.save()
        
        // Delete from local database
        context.delete(habit)
        try? context.save()
        
        print("✅ DashboardView: Habit deleted locally")
        
        // Trigger sync in background
        Task { @MainActor in
            await appState.syncWithContext(context)
        }
    }
}


