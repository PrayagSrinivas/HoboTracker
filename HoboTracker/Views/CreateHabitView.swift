//
//  CreateHabitView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 13/03/26.
//


import SwiftUI
import SwiftData

struct CreateHabitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = CreateHabitViewModel()
    
    var body: some View {
        Form {
            detailsSection
            iconSection
            colorSection
            previewSection
        }
        .navigationTitle("Create Habit")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveHabit()
                }
                .disabled(viewModel.isSaveDisabled)
            }
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("Habit Name", text: $viewModel.name)
            TextField("Description (Optional)", text: $viewModel.habitDescription)
        } header: {
            Text("Details")
        }
    }

    private var iconSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.availableIcons, id: \.self) { icon in
                        iconCell(for: icon)
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Icon")
        }
    }

    private func iconCell(for icon: String) -> some View {
        let isSelected = viewModel.selectedIcon == icon
        return Image(systemName: icon)
            .font(.title2)
            .frame(width: 44, height: 44)
            .background(isSelected ? viewModel.color(from: viewModel.selectedColorHex).opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? viewModel.color(from: viewModel.selectedColorHex) : .primary)
            .clipShape(Circle())
            .onTapGesture {
                withAnimation { viewModel.selectedIcon = icon }
            }
    }

    private var colorSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.availableColors, id: \.self) { hex in
                        colorSwatch(for: hex)
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Color")
        }
    }

    private func colorSwatch(for hex: String) -> some View {
        let isSelected = viewModel.selectedColorHex == hex
        return Circle()
            .fill(viewModel.color(from: hex))
            .frame(width: 36, height: 36)
            .overlay(
                Circle()
                    .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                    .padding(-4)
            )
            .onTapGesture {
                withAnimation { viewModel.selectedColorHex = hex }
            }
    }

    private var previewSection: some View {
        Section {
            HStack {
                Spacer()
                VStack {
                    Image(systemName: viewModel.selectedIcon)
                        .font(.system(size: 40))
                        .foregroundColor(viewModel.color(from: viewModel.selectedColorHex))
                        .padding(.bottom, 8)

                    Text(viewModel.name.isEmpty ? "New Habit" : viewModel.name)
                        .font(.headline)
                }
                .padding()
                Spacer()
            }
        } header: {
            Text("Preview")
        }
    }

    // MARK: - Actions
    private func saveHabit() {
        print("💾 CreateHabitView: Creating new habit '\(viewModel.name)'")
        let habit = viewModel.save(context: context)
        
        // Set owner ID BEFORE saving context
        if let userId = appState.authService.userId {
            habit.ownerId = userId
            print("💾 CreateHabitView: Set ownerId to \(userId)")
        } else {
            print("⚠️ CreateHabitView: No userId available, habit won't sync")
        }
        
        // Ensure sync status is set
        habit.syncStatus = "pending"
        habit.updatedAt = Date()
        
        // Save the context
        do {
            try context.save()
            print("✅ CreateHabitView: Habit saved to local database")
            print("💾 CreateHabitView: Habit ID: \(habit.id)")
            print("💾 CreateHabitView: Sync Status: \(habit.syncStatus)")
            print("💾 CreateHabitView: Owner ID: \(habit.ownerId ?? "nil")")
            
            // Verify the habit exists in this context
            let habitId = habit.id
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { habit in
                habit.id == habitId
            })
            if let fetchedHabits = try? context.fetch(descriptor) {
                print("🔍 CreateHabitView: Verification - Found \(fetchedHabits.count) habits with this ID in current context")
                if let found = fetchedHabits.first {
                    print("   ✓ Name: \(found.name), Status: \(found.syncStatus), OwnerID: \(found.ownerId ?? "nil")")
                }
            }
            
            // Check all habits in this context
            let allDescriptor = FetchDescriptor<Habit>()
            if let allHabits = try? context.fetch(allDescriptor) {
                print("🔍 CreateHabitView: Total habits in this context: \(allHabits.count)")
                for h in allHabits {
                    print("   - '\(h.name)' | Status: \(h.syncStatus) | ID: \(h.id)")
                }
            }
            
        } catch {
            print("❌ CreateHabitView: Failed to save habit: \(error.localizedDescription)")
            return
        }
        
        // Trigger sync with the SAME context where we just saved
        Task { @MainActor in
            print("🔄 CreateHabitView: Triggering sync with current context...")
            // Small delay to ensure persistence is complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await appState.syncWithContext(context)
        }
        
        dismiss()
    }
}
