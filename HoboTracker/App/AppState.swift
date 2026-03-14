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
        do {
            print("🔐 AppState: Initiating Google sign-in...")
            try await authService.signInWithGoogle()
            print("🔐 AppState: Google sign-in completed")
            print("🔐 AppState: isAuthenticated = \(authService.isAuthenticated)")
            print("🔐 AppState: user ID = \(authService.userId ?? "none")")
            
            // Manually update isAuthenticated to ensure UI updates
            isAuthenticated = authService.isAuthenticated
            
            // Sync the new user's habits from Supabase
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
        do {
            print("🔐 AppState: Initiating email sign-in for: \(email)")
            try await authService.signInWithEmail(email: email, password: password)
            print("🔐 AppState: Email sign-in completed")
            print("🔐 AppState: isAuthenticated = \(authService.isAuthenticated)")
            print("🔐 AppState: user ID = \(authService.userId ?? "none")")
            
            // Manually update isAuthenticated to ensure UI updates
            isAuthenticated = authService.isAuthenticated
            
            // Sync the new user's habits from Supabase
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
        do {
            print("🔐 AppState: Initiating email sign-up for: \(email)")
            try await authService.signUpWithEmail(email: email, password: password)
            print("🔐 AppState: Email sign-up completed")
            print("🔐 AppState: isAuthenticated = \(authService.isAuthenticated)")
            print("🔐 AppState: user ID = \(authService.userId ?? "none")")
            
            // Manually update isAuthenticated to ensure UI updates
            isAuthenticated = authService.isAuthenticated
            
            // Sync the new user's habits from Supabase
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
        
        // Note: We keep local habits so they can be synced if user signs back in
        // If you want to clear all habits on sign out, call clearLocalHabits()
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
        // Called when a new user signs in
        // Pull habits for the new user from Supabase
        guard authService.isAuthenticated, let context = modelContext else { return }
        
        print("🔄 AppState: New user signed in, syncing their habits...")
        await syncEngine.syncIfNeeded(context: context)
    }

    func syncIfPossible() async {
        guard authService.isAuthenticated, let context = modelContext else {
            print("🔐 AppState: Cannot sync - not authenticated or no model context")
            return
        }
        print("🔄 AppState: Starting sync...")
        await syncEngine.syncIfNeeded(context: context)
    }
    
    func syncWithContext(_ context: ModelContext) async {
        guard authService.isAuthenticated else {
            print("🔐 AppState: Cannot sync - not authenticated")
            return
        }
        print("🔄 AppState: Starting sync with provided context...")
        
        // Try the provided context first
        await syncEngine.syncIfNeeded(context: context)
        
        // If we have a different stored context, also try that
        if let storedContext = modelContext, storedContext !== context {
            print("🔄 AppState: Also syncing with stored main context...")
            await syncEngine.syncIfNeeded(context: storedContext)
        }
    }
}
