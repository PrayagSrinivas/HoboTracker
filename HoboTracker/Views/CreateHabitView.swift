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
    @StateObject private var viewModel = CreateHabitViewModel()
    
    var body: some View {
        NavigationStack {
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
        viewModel.save(context: context)
        dismiss()
    }
}
