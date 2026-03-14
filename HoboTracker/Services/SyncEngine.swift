import Foundation
import SwiftData

@MainActor
final class SyncEngine {
    private let authService: AuthService
    private let networkMonitor: NetworkMonitor
    private let remoteStore: SupabaseHabitStore
    private let onError: ((String) -> Void)?
    private let lastSyncKey = "last_sync_at"

    init(
        authService: AuthService,
        networkMonitor: NetworkMonitor,
        remoteStore: SupabaseHabitStore = SupabaseHabitStore(),
        onError: ((String) -> Void)? = nil
    ) {
        self.authService = authService
        self.networkMonitor = networkMonitor
        self.remoteStore = remoteStore
        self.onError = onError
    }

    func syncIfNeeded(context: ModelContext) async {
        guard networkMonitor.isOnline else {
            print("🌐 SyncEngine: Skipping sync - offline")
            return
        }
        guard let userId = authService.userId else {
            print("🔐 SyncEngine: Skipping sync - no user ID")
            return
        }

        print("🔄 SyncEngine: Starting sync for user: \(userId)")
        await pushLocalChanges(context: context, userId: userId)
        await pullRemoteChanges(context: context, userId: userId)
        updateLastSyncDate(Date())
        print("✅ SyncEngine: Sync completed")
    }

    private func pushLocalChanges(context: ModelContext, userId: String) async {
        // First, let's see ALL habits in the database
        let allDescriptor = FetchDescriptor<Habit>()
        if let allHabits = try? context.fetch(allDescriptor) {
            print("📊 SyncEngine: Total habits in database: \(allHabits.count)")
            let userIdLower = userId.lowercased()
            let currentUserHabits = allHabits.filter { $0.ownerId?.lowercased() == userIdLower }
            let otherUserHabits = allHabits.filter { $0.ownerId != nil && $0.ownerId?.lowercased() != userIdLower }
            let unownedHabits = allHabits.filter { $0.ownerId == nil }
            
            print("   📊 Current user (\(userId)): \(currentUserHabits.count) habits")
            print("   📊 Other users: \(otherUserHabits.count) habits")
            print("   📊 Unowned: \(unownedHabits.count) habits")
            
            for habit in allHabits {
                let userTag = habit.ownerId?.lowercased() == userIdLower ? "✓ YOUR" : (habit.ownerId == nil ? "⚠️ NONE" : "✗ OTHER")
                print("   - [\(userTag)] '\(habit.name)' | Status: \(habit.syncStatus) | OwnerID: \(habit.ownerId ?? "nil")")
            }
        }
        
        let predicate = #Predicate<Habit> { $0.syncStatus != "synced" }
        let descriptor = FetchDescriptor<Habit>(predicate: predicate)

        guard let pending = try? context.fetch(descriptor) else {
            print("⚠️ SyncEngine: Failed to fetch pending habits")
            return
        }

        print("📤 SyncEngine: Found \(pending.count) habits to sync")

        for habit in pending {
            habit.ownerId = habit.ownerId ?? userId
            habit.updatedAt = Date()

            let dto = HabitDTO(
                id: habit.id,
                ownerId: habit.ownerId ?? userId,
                name: habit.name,
                habitDescription: habit.habitDescription,
                iconName: habit.iconName,
                colorHex: habit.colorHex,
                loggedDates: habit.loggedDates,
                creationDate: habit.creationDate,
                updatedAt: habit.updatedAt,
                isDeleted: habit.isDeleted
            )

            do {
                if habit.isDeleted {
                    print("🗑️ SyncEngine: Deleting habit '\(habit.name)' (ID: \(habit.id))")
                    try await remoteStore.delete(id: habit.id, userId: userId)
                } else {
                    print("💾 SyncEngine: Upserting habit '\(habit.name)' (ID: \(habit.id))")
                    try await remoteStore.upsert(dto)
                }
                habit.syncStatus = "synced"
                print("✅ SyncEngine: Successfully synced habit '\(habit.name)'")
            } catch {
                habit.syncStatus = "failed"
                let errorMessage = "Push failed for \(habit.name): \(error.localizedDescription)"
                print("❌ SyncEngine: \(errorMessage)")
                onError?(errorMessage)
            }
        }

        try? context.save()
    }

    private func pullRemoteChanges(context: ModelContext, userId: String) async {
        do {
            let since = lastSyncDate()
            print("📥 SyncEngine: Pulling remote changes since: \(since?.description ?? "beginning")")
            let remoteHabits = try await remoteStore.fetchUpdatedSince(since, userId: userId)
            print("📥 SyncEngine: Found \(remoteHabits.count) remote habits")

            for remote in remoteHabits {
                let predicate = #Predicate<Habit> { $0.id == remote.id }
                let descriptor = FetchDescriptor<Habit>(predicate: predicate)
                let local = try? context.fetch(descriptor).first

                if remote.isDeleted {
                    if let local {
                        print("🗑️ SyncEngine: Deleting local habit '\(local.name)' (ID: \(local.id))")
                        context.delete(local)
                    }
                    continue
                }

                if let local {
                    print("🔄 SyncEngine: Updating local habit '\(local.name)' (ID: \(local.id))")
                    local.name = remote.name
                    local.habitDescription = remote.habitDescription
                    local.iconName = remote.iconName
                    local.colorHex = remote.colorHex
                    local.loggedDates = remote.loggedDates
                    local.creationDate = remote.creationDate
                    local.updatedAt = remote.updatedAt
                    local.ownerId = remote.ownerId
                    local.isDeleted = remote.isDeleted
                    local.syncStatus = "synced"
                } else {
                    print("➕ SyncEngine: Creating new local habit '\(remote.name)' (ID: \(remote.id))")
                    let habit = Habit(
                        name: remote.name,
                        habitDescription: remote.habitDescription,
                        iconName: remote.iconName,
                        colorHex: remote.colorHex
                    )
                    habit.id = remote.id
                    habit.loggedDates = remote.loggedDates
                    habit.creationDate = remote.creationDate
                    habit.updatedAt = remote.updatedAt
                    habit.ownerId = remote.ownerId
                    habit.isDeleted = remote.isDeleted
                    habit.syncStatus = "synced"
                    context.insert(habit)
                }
            }

            try? context.save()
            print("✅ SyncEngine: Successfully processed \(remoteHabits.count) remote habits")
        } catch {
            let errorMessage = "Pull failed: \(error.localizedDescription)"
            print("❌ SyncEngine: \(errorMessage)")
            onError?(errorMessage)
        }
    }

    private func lastSyncDate() -> Date? {
        if let stored = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            return stored
        }
        return nil
    }

    private func updateLastSyncDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastSyncKey)
    }
}
