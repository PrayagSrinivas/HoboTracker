import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Activity", systemImage: "square.grid.2x2")
                }

            ExampleHabitsView()
                .tabItem {
                    Label("Examples", systemImage: "sparkles")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}
