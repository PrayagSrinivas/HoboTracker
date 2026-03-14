import Combine
import SwiftData
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var isShowingCreateHabit = false
    @Published var isGridLayout = true

    func toggleLayout() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isGridLayout.toggle()
        }
    }

    func toggleHabit(_ habit: Habit, context: ModelContext, userId: String?) {
        let today = Calendar.current.startOfDay(for: Date())
        if habit.isLoggedToday {
            habit.loggedDates.removeAll { Calendar.current.isDate($0, inSameDayAs: today) }
        } else {
            habit.loggedDates.append(today)
        }
        habit.updatedAt = Date()
        habit.syncStatus = "pending"
        
        // Ensure ownerId is set
        if habit.ownerId == nil {
            habit.ownerId = userId
        }
        
        try? context.save()
    }
    
    func deleteHabit(_ habit: Habit, context: ModelContext) {
        print("🗑️ DashboardViewModel: Deleting habit '\(habit.name)' (ID: \(habit.id))")
        
        // Mark as deleted for sync
        habit.isDeleted = true
        habit.updatedAt = Date()
        habit.syncStatus = "pending"
        
        // Save to trigger sync, then actually delete
        try? context.save()
        
        // Delete from local database
        context.delete(habit)
        try? context.save()
        
        print("✅ DashboardViewModel: Habit deleted locally")
    }

    func color(from hex: String) -> Color {
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
