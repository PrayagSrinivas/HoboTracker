import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if appState.isAuthenticated || appState.allowOffline {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            appState.setModelContext(modelContext)
            await appState.start()
        }
        .onChange(of: appState.isAuthenticated) { newValue in
            print("🔐 AuthGateView: isAuthenticated changed to: \(newValue)")
        }
        .onChange(of: appState.allowOffline) { newValue in
            print("🔐 AuthGateView: allowOffline changed to: \(newValue)")
        }
        .onChange(of: appState.networkMonitor.isOnline) { isOnline in
            print("🌐 AuthGateView: Network status changed to: \(isOnline ? "online" : "offline")")
            if isOnline {
                Task {
                    await appState.syncIfPossible()
                }
            }
        }
    }
}
