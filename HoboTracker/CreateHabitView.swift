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
    
    // Form State
    @State private var name: String = ""
    @State private var habitDescription: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedColorHex: String = "#007AFF"
    
    // Sample data for selection
    let availableIcons = [
        "star.fill", "flame.fill", "drop.fill", "figure.walk", 
        "book.fill", "heart.fill", "moon.fill", "leaf.fill",
        "bicycle", "brain.head.profile"
    ]
    
    let availableColors = [
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#34C759", // Green
        "#007AFF", // Blue
        "#AF52DE", // Purple
        "#FF2D55"  // Pink
    ]
    
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("Habit Name", text: $name)
            TextField("Description (Optional)", text: $habitDescription)
        } header: {
            Text("Details")
        }
    }

    private var iconSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(availableIcons, id: \.self) { icon in
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
        let isSelected = selectedIcon == icon
        return Image(systemName: icon)
            .font(.title2)
            .frame(width: 44, height: 44)
            .background(isSelected ? color(from: selectedColorHex).opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? color(from: selectedColorHex) : .primary)
            .clipShape(Circle())
            .onTapGesture {
                withAnimation { selectedIcon = icon }
            }
    }

    private var colorSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(availableColors, id: \.self) { hex in
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
        let isSelected = selectedColorHex == hex
        return Circle()
            .fill(color(from: hex))
            .frame(width: 36, height: 36)
            .overlay(
                Circle()
                    .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                    .padding(-4)
            )
            .onTapGesture {
                withAnimation { selectedColorHex = hex }
            }
    }

    private var previewSection: some View {
        Section {
            HStack {
                Spacer()
                VStack {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 40))
                        .foregroundColor(color(from: selectedColorHex))
                        .padding(.bottom, 8)

                    Text(name.isEmpty ? "New Habit" : name)
                        .font(.headline)
                }
                .padding()
                Spacer()
            }
        } header: {
            Text("Preview")
        }
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
    
    // MARK: - Actions
    private func saveHabit() {
        let newHabit = Habit(
            name: name,
            habitDescription: habitDescription,
            iconName: selectedIcon,
            colorHex: selectedColorHex
        )
        
        // Insert into SwiftData context
        context.insert(newHabit)
        
        // Reset form for the next habit
        name = ""
        habitDescription = ""
        selectedIcon = availableIcons[0]
        selectedColorHex = availableColors[4]
        
        // Note: Since this is a TabView, you might want to programmatically 
        // switch the user back to the Dashboard tab here using a @Binding or @Environment object.
    }
}
