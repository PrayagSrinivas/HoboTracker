import Combine
import SwiftData
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let authService = AuthService()
    let networkMonitor = NetworkMonitor()
    lazy var syncEngine: SyncEngine = {
        SyncEngine(
            authService: authService,
            networkMonitor: networkMonitor,
            onError: { [weak self] message in
                Task { @MainActor in
                    self?.lastSyncError = message
                }
            }
        )
    }()

    @Published var allowOffline = false
    @Published var isAuthenticated = false
    @Published var lastSyncError: String?
    @Published var isLoading = false
    @Published var loadingMessage: String?

    private var modelContext: ModelContext?
    private var cancellables: Set<AnyCancellable> = []

    init() {
        authService.$session
            .map { $0 != nil }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
    }

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    func start() async {
        await authService.loadSession()
        isAuthenticated = authService.isAuthenticated
        if authService.isAuthenticated, let context = modelContext {
            await syncEngine.syncIfNeeded(context: context)
        }
    }

    func signInWithGoogle() async {
        showLoading()
        defer { hideLoading() }
        
        do {
            print("🔐 AppState: Initiating Google sign-in...")
            try await authService.signInWithGoogle()
            print("🔐 AppState: Google sign-in completed")
            print("🔐 AppState: isAuthenticated = \(authService.isAuthenticated)")
            print("🔐 AppState: user ID = \(authService.userId ?? "none")")
            
            isAuthenticated = authService.isAuthenticated
            
            if let context = modelContext {
                print("🔄 AppState: Syncing new user's habits from Supabase...")
                await syncEngine.syncIfNeeded(context: context)
            }
        } catch {
            print("❌ AppState: Google sign-in failed: \(error.localizedDescription)")
            lastSyncError = "Sign-in failed: \(error.localizedDescription)"
        }
    }
    
    func signInWithEmail(email: String, password: String) async {
        showLoading()
        defer { hideLoading() }
        
        do {
            print("🔐 AppState: Initiating email sign-in for: \(email)")
            try await authService.signInWithEmail(email: email, password: password)
            print("🔐 AppState: Email sign-in completed")
            print("🔐 AppState: isAuthenticated = \(authService.isAuthenticated)")
            print("🔐 AppState: user ID = \(authService.userId ?? "none")")
            
            isAuthenticated = authService.isAuthenticated
            
            if let context = modelContext {
                print("🔄 AppState: Syncing user's habits from Supabase...")
                await syncEngine.syncIfNeeded(context: context)
            }
        } catch {
            print("❌ AppState: Email sign-in failed: \(error.localizedDescription)")
            lastSyncError = "Sign-in failed: \(error.localizedDescription)"
        }
    }
    
    func signUpWithEmail(email: String, password: String) async {
        showLoading()
        defer { hideLoading() }
        
        do {
            print("🔐 AppState: Initiating email sign-up for: \(email)")
            try await authService.signUpWithEmail(email: email, password: password)
            print("🔐 AppState: Email sign-up completed")
            print("🔐 AppState: isAuthenticated = \(authService.isAuthenticated)")
            print("🔐 AppState: user ID = \(authService.userId ?? "none")")
            
            isAuthenticated = authService.isAuthenticated
            
            if let context = modelContext {
                print("🔄 AppState: Syncing user's habits from Supabase...")
                await syncEngine.syncIfNeeded(context: context)
            }
        } catch {
            print("❌ AppState: Email sign-up failed: \(error.localizedDescription)")
            lastSyncError = "Sign-up failed: \(error.localizedDescription)"
        }
    }

    func signOut() async {
        print("🔐 AppState: Signing out user: \(authService.userId ?? "unknown")")
        await authService.signOut()
        isAuthenticated = false
        print("🔐 AppState: User signed out, local habits preserved")
    }
    
    func clearLocalHabits() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Habit>()
        if let allHabits = try? context.fetch(descriptor) {
            print("🗑️ AppState: Clearing \(allHabits.count) local habits")
            for habit in allHabits {
                context.delete(habit)
            }
            try? context.save()
            print("✅ AppState: Local habits cleared")
        }
    }
    
    func switchUser() async {
        guard authService.isAuthenticated, let context = modelContext else { return }
        print("🔄 AppState: New user signed in, syncing their habits...")
        await syncEngine.syncIfNeeded(context: context)
    }

    func syncIfPossible() async {
        guard authService.isAuthenticated, let context = modelContext else {
            print("🔐 AppState: Cannot sync - not authenticated or no model context")
            return
        }
        showLoading()
        defer { hideLoading() }
        
        print("🔄 AppState: Starting sync...")
        await syncEngine.syncIfNeeded(context: context)
    }
    
    func syncWithContext(_ context: ModelContext) async {
        guard authService.isAuthenticated else {
            print("🔐 AppState: Cannot sync - not authenticated")
            return
        }
        showLoading()
        defer { hideLoading() }
        
        print("🔄 AppState: Starting sync with provided context...")
        await syncEngine.syncIfNeeded(context: context)
        
        if let storedContext = modelContext, storedContext !== context {
            print("🔄 AppState: Also syncing with stored main context...")
            await syncEngine.syncIfNeeded(context: storedContext)
        }
    }
    
    // MARK: - Loading State Helpers
    
    func showLoading(_ message: String? = nil) {
        isLoading = true
        loadingMessage = message
        print("⏳ AppState: Showing loader")
    }
    
    func hideLoading() {
        isLoading = false
        loadingMessage = nil
        print("✅ AppState: Hiding loader")
    }
}
