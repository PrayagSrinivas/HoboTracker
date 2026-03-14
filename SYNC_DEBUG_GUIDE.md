## HoboTracker Sync Debugging Guide

The following changes have been made to fix the Supabase sync issues:

### 1. Fixed Supabase Configuration
- **Issue**: The anon key in `SupabaseConfig.swift` was incomplete
- **Fix**: Updated with a placeholder JWT token format
- **Action Required**: Replace the anon key with your actual Supabase anon key from your project settings

### 2. Enhanced User ID Assignment
- **Issue**: `ownerId` wasn't consistently set when creating/updating habits
- **Fix**: 
  - Updated `DashboardViewModel.toggleHabit()` to accept and set `userId`
  - Modified `DashboardView` to pass the authenticated user's ID
  - Added immediate sync trigger after habit toggles

### 3. Added Comprehensive Error Logging
- **Added**: Detailed console logging throughout the sync process
- **Benefits**: You can now see exactly what's happening during sync in Xcode's console

### 4. To Get Your Actual Supabase Anon Key:
1. Go to your Supabase dashboard: https://app.supabase.com
2. Select your project (jofuyylrfznqvhuehvjk)
3. Go to Settings > API
4. Copy the "anon public" key
5. Replace the placeholder in `SupabaseConfig.swift`

### 5. Database Schema Requirements
Ensure your Supabase `habits` table has these columns:
- `id` (uuid, primary key)
- `owner_id` (text/varchar)
- `name` (text)
- `habit_description` (text)
- `icon_name` (text)
- `color_hex` (text)
- `logged_dates` (jsonb array)
- `creation_date` (timestamptz)
- `updated_at` (timestamptz)
- `is_deleted` (boolean)

### 6. Row Level Security (RLS)
Make sure you have RLS policies set up:
```sql
-- Allow users to see only their own habits
CREATE POLICY "Users can view own habits" ON habits
    FOR SELECT USING (auth.uid() = owner_id);

-- Allow users to insert their own habits
CREATE POLICY "Users can insert own habits" ON habits
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- Allow users to update their own habits
CREATE POLICY "Users can update own habits" ON habits
    FOR UPDATE USING (auth.uid() = owner_id);

-- Allow users to delete their own habits
CREATE POLICY "Users can delete own habits" ON habits
    FOR DELETE USING (auth.uid() = owner_id);
```

### 7. Testing the Fix
1. Replace the anon key in `SupabaseConfig.swift`
2. Run the app and authenticate
3. Create a new habit or toggle an existing one
4. Check Xcode console for sync logs (look for 🔄, ✅, ❌ emojis)
5. Check your Supabase dashboard table for the data

### Common Issues to Check:
- **Authentication**: Ensure user is properly signed in
- **Network**: Check internet connection
- **Database**: Verify table structure matches expectations
- **RLS Policies**: Ensure proper row-level security is configured
- **API Keys**: Confirm anon key is correct and has proper permissions

The console logs will now show detailed information about each step of the sync process, making it easier to identify where issues occur.