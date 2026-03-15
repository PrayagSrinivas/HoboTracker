import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
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
            .onChange(of: appState.isAuthenticated) { _, newValue in
                print("🔐 AuthGateView: isAuthenticated changed to: \(newValue)")
            }
            .onChange(of: appState.allowOffline) { _, newValue in
                print("🔐 AuthGateView: allowOffline changed to: \(newValue)")
            }
            .onChange(of: appState.networkMonitor.isOnline) { _, isOnline in
                print("🌐 AuthGateView: Network status changed to: \(isOnline ? "online" : "offline")")
                if isOnline {
                    Task {
                        await appState.syncIfPossible()
                    }
                }
            }
            
            if appState.isLoading {
                // Just a simple spinner - no background, no box, no text
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .scaleEffect(1.5)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: appState.isLoading)
            }
        }
    }
}
