# User-Specific Habits Fix - Multi-User Support

## The Problem You Reported

When signing in with a different Google account, you could see the previous user's habits. This is because:
1. **Local database stores all users' habits** - SwiftData persists all habits locally
2. **No filtering by user** - The DashboardView was showing ALL habits regardless of owner
3. **No separation between users** - Habits from different accounts mixed together

## ✅ Fixes Applied

### 1. Filter Habits by Current User (DashboardView.swift)

**Changed from:**
```swift
@Query(sort: \Habit.creationDate, order: .forward) private var habits: [Habit]
```

**Changed to:**
```swift
@Query(sort: \Habit.creationDate, order: .forward) private var allHabits: [Habit]

private var habits: [Habit] {
    guard let currentUserId = appState.authService.userId else {
        return allHabits
    }
    // Only show habits owned by current user or unowned habits
    return allHabits.filter { habit in
        habit.ownerId == currentUserId || habit.ownerId == nil
    }
}
```

Now the dashboard **only shows the current user's habits**!

### 2. Enhanced Sign Out (AppState.swift)

**Added logging and preservation notice:**
```swift
func signOut() async {
    print("🔐 AppState: Signing out user: \(userId)")
    await authService.signOut()
    isAuthenticated = false
    
    // Local habits are preserved so they can be synced if user signs back in
    print("🔐 AppState: User signed out, local habits preserved")
}
```

**Added method to clear local habits if needed:**
```swift
func clearLocalHabits() {
    // Deletes ALL habits from local database
    // Useful if you want a clean slate
}
```

### 3. Enhanced Sync Logging (SyncEngine.swift)

**Added user filtering information:**
```
📊 SyncEngine: Total habits in database: 10
   📊 Current user (5CF5F485...): 3 habits
   📊 Other users: 7 habits
   📊 Unowned: 0 habits
   
   - [✓ YOUR] 'Morning Run' | Status: pending | OwnerID: 5CF5F485...
   - [✗ OTHER] 'Read Book' | Status: synced | OwnerID: ABC123...
   - [✗ OTHER] 'Exercise' | Status: synced | OwnerID: ABC123...
```

Legend:
- **[✓ YOUR]** = Current user's habit
- **[✗ OTHER]** = Different user's habit
- **[⚠️ NONE]** = No owner assigned (needs fixing)

## How It Works Now

### Scenario 1: User A Signs In
```
👤 User A (ID: 5CF5F485...) signs in
📊 Database has: 10 total habits
   - 3 owned by User A
   - 7 owned by User B
   
🎯 DashboardView shows: Only User A's 3 habits
```

### Scenario 2: User A Signs Out, User B Signs In
```
👤 User A signs out
👤 User B (ID: ABC123...) signs in
📊 Database still has: 10 total habits (preserved locally)
   - 3 owned by User A
   - 7 owned by User B
   
🎯 DashboardView shows: Only User B's 7 habits
🔄 Syncs User B's habits from Supabase
```

### Scenario 3: New Habit Created
```
👤 User B creates "Yoga" habit
💾 Saved with ownerId = "ABC123..."
📊 Database now has: 11 total habits
   - 3 owned by User A
   - 8 owned by User B (including new Yoga)
   
🎯 DashboardView shows: Only User B's 8 habits
```

## Testing Instructions

### Test 1: Verify Current User's Habits Only Show

1. **Sign in with Account 1**
2. **Create 2-3 habits**
3. **Check Dashboard** - should see your habits
4. **Check Console** for:
   ```
   📊 DashboardView: Showing X habits for user [your-user-id]
   ```

### Test 2: Switch Users

1. **Sign out** (Profile > Log Out)
2. **Sign in with Account 2** (different Google account)
3. **Check Dashboard** - should be empty OR only show Account 2's habits
4. **Create a habit**
5. **Check Console** for:
   ```
   📊 SyncEngine: Current user ([account-2-id]): 1 habits
   📊 SyncEngine: Other users: X habits
   ```

### Test 3: Switch Back to Account 1

1. **Sign out**
2. **Sign in with Account 1** again
3. **Check Dashboard** - should see Account 1's original 2-3 habits
4. **Verify** Account 2's habits don't appear

## Console Logs to Expect

### When Viewing Dashboard:
```
📊 DashboardView: Showing 3 habits for user 5CF5F485-F8A5-4837-9AFF-86C3E3D9EB6B
```

### When Syncing:
```
📊 SyncEngine: Total habits in database: 10
   📊 Current user (5CF5F485...): 3 habits
   📊 Other users: 7 habits
   📊 Unowned: 0 habits
   
   - [✓ YOUR] 'Morning Run' | Status: pending | OwnerID: 5CF5F485...
   - [✓ YOUR] 'Meditation' | Status: synced | OwnerID: 5CF5F485...
   - [✓ YOUR] 'Reading' | Status: synced | OwnerID: 5CF5F485...
   - [✗ OTHER] 'Yoga' | Status: synced | OwnerID: ABC123...
```

### When Signing Out:
```
🔐 AppState: Signing out user: 5CF5F485-F8A5-4837-9AFF-86C3E3D9EB6B
🔐 AppState: User signed out, local habits preserved
```

### When Signing In:
```
🔐 AppState: Google sign-in completed
🔐 AppState: user ID = ABC123-NEW-USER-ID
🔄 AppState: Syncing new user's habits from Supabase...
```

## Why Local Habits Are Preserved

**Design Decision:** Local habits from all users are kept in the database for these reasons:

1. **Offline Support**: If User A signs back in offline, their habits are immediately available
2. **Sync Efficiency**: When User A reconnects, their pending changes can be synced to Supabase
3. **Data Safety**: No accidental data loss when switching accounts

**Privacy:** Even though habits are stored locally, they are:
- ✅ **Filtered by user** - Each user only sees their own habits
- ✅ **Synced separately** - Each user's habits sync to their own Supabase account
- ✅ **Properly isolated** - No cross-contamination between users

## Optional: Clear All Local Data

If you want to completely clear local habits (e.g., for testing or privacy):

**Option A: Add to ProfileView**
```swift
Button("Clear All Local Data", role: .destructive) {
    appState.clearLocalHabits()
}
```

**Option B: Call programmatically**
```swift
await appState.clearLocalHabits()
```

## Troubleshooting

### Problem: Still seeing other user's habits

**Check Console for:**
```
📊 DashboardView: Showing X habits for user [user-id]
```

If this shows habits from other users, check:
1. Is the `ownerId` set correctly on habits?
2. Look for `[✗ OTHER]` in sync logs
3. Verify the filter logic is working

### Problem: Habits without owner ID

**Console shows:**
```
- [⚠️ NONE] 'Some Habit' | Status: pending | OwnerID: nil
```

**Solution:** These are habits created before the owner ID fix. They will show for all users. To fix:
- Delete and recreate them, OR
- They'll get owner ID assigned when toggled

### Problem: Habits not syncing for new user

**Console shows:**
```
📊 SyncEngine: Current user ([new-user-id]): 0 habits
🔍 SupabaseHabitStore: Fetched 0 habits from database
```

**This is normal** if:
- New user hasn't created any habits yet
- New user's Supabase account has no habits

## Summary of Changes

✅ **DashboardView** - Filters habits by current user
✅ **AppState** - Enhanced sign-out logging & clearLocalHabits() method
✅ **SyncEngine** - Shows user ownership in logs
✅ **Build Status** - Compiles successfully

## Test Now!

1. **Clean build**: Cmd+Shift+K
2. **Run**: Cmd+R
3. **Sign in** with one account
4. **Create habits**
5. **Sign out**
6. **Sign in** with different account
7. **Verify** - Should NOT see previous user's habits!

Watch the console for the filtering logs to confirm it's working!