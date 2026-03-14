# Google Sign-In Troubleshooting Guide for HoboTracker

## Issue
After tapping "Continue with Google" and completing the sign-in process, the app stays on the Login Screen instead of navigating to the main app.

## Changes Made

### 1. Enhanced Logging in AuthService
- Added detailed console logs at each step of the sign-in process
- You'll now see logs with 🔐 emoji showing the authentication flow

### 2. Improved Error Handling in AppState
- Better error catching and display
- Errors will now appear on the login screen

### 3. Added Debugging to AuthGateView
- Tracks changes to `isAuthenticated` and `allowOffline` states
- Logs network status changes

### 4. Enhanced LoginView
- Displays error messages if sign-in fails
- Added logging when view appears

### 5. Added URL Handler to HoboTrackerApp
- Logs when the app receives OAuth callback URLs
- Helps debug URL scheme issues

## Root Causes to Check

### 1. Invalid Supabase Anon Key ⚠️
**CRITICAL**: The anon key in `SupabaseConfig.swift` is currently a placeholder.

**To Fix**:
1. Go to https://app.supabase.com/project/jofuyylrfznqvhuehvjk/settings/api
2. Copy your **anon public** key (it's a long JWT token)
3. Replace the placeholder in `SupabaseConfig.swift`:
```swift
static let anonKey = "YOUR_ACTUAL_ANON_KEY_HERE"
```

### 2. Supabase Auth Configuration
In your Supabase dashboard (https://app.supabase.com/project/jofuyylrfznqvhuehvjk/auth/url-configuration):

1. **Add Redirect URLs**:
   - `srinivas.co.HoboTracker://login-callback`
   - `srinivas.co.HoboTracker://**`

2. **Site URL**: Set to your app's URL or `http://localhost:3000` for testing

3. **Enable Google Provider**:
   - Go to Authentication > Providers
   - Enable Google OAuth
   - Add your Google OAuth Client ID and Secret

### 3. Google OAuth Setup
In Google Cloud Console:

1. Create OAuth 2.0 Client ID (iOS type)
2. Add bundle identifier: `srinivas.co.HoboTracker`
3. Add the Client ID and Secret to Supabase

### 4. URL Scheme Format Issue
The current URL scheme `srinivas.co.HoboTracker` contains dots, which might cause issues.

**Consider simplifying to**: `hobotracker`

If you change this, update in 3 places:
1. `SupabaseConfig.swift`:
```swift
static let callbackScheme = "hobotracker"
static let redirectURL = URL(string: "hobotracker://login-callback")!
```

2. `Info.plist`:
```xml
<string>hobotracker</string>
```

3. Supabase Dashboard redirect URLs

## Testing Steps

1. **Clean Build**: Product > Clean Build Folder (Cmd+Shift+K)
2. **Rebuild**: Build the app (Cmd+B)
3. **Run**: Launch on simulator or device
4. **Watch Console**: Open Console in Xcode (Cmd+Shift+C) and filter for logs
5. **Try Sign-In**: Tap "Continue with Google"

## What to Look For in Console

### Successful Flow:
```
🔐 LoginView: View appeared
🔐 AppState: Initiating Google sign-in...
🔐 AuthService: Starting Google sign-in...
🔐 AuthService: Auth URL generated: https://...
🔐 AuthService: Callback URL received: srinivas.co.HoboTracker://...
🔗 HoboTrackerApp: Received URL: srinivas.co.HoboTracker://...
🔐 AuthService: Exchanging callback URL for session...
✅ AuthService: Sign-in successful! User ID: ...
🔐 AppState: Google sign-in completed
🔐 AuthGateView: isAuthenticated changed to: true
```

### Common Errors:

**Invalid API Key**:
```
❌ AuthService: Web auth session error: Invalid API key
```
→ Replace the anon key in SupabaseConfig.swift

**Invalid Redirect URL**:
```
❌ AuthService: Web auth session error: redirect_uri_mismatch
```
→ Add the redirect URL to Supabase dashboard

**URL Scheme Not Configured**:
```
🔗 HoboTrackerApp: Received URL: (nothing appears)
```
→ Check Info.plist and URL scheme configuration

**User Cancels**:
```
❌ AuthService: Web auth session error: The operation was cancelled
```
→ User cancelled the sign-in, this is normal

## Quick Test: Continue Offline

To verify the UI navigation works:
1. Tap "Continue Offline" button
2. App should navigate to MainTabView
3. If this works, the issue is specifically with OAuth, not UI navigation

## Additional Debugging

If issues persist, enable Supabase client logging by adding to `SupabaseClientProvider.swift`:
```swift
let client = SupabaseClient(
    supabaseURL: SupabaseConfig.url, 
    supabaseKey: SupabaseConfig.anonKey,
    options: .init(
        auth: .init(
            flowType: .pkce
        )
    )
)
```

## Next Steps

1. Replace the Supabase anon key
2. Configure redirect URLs in Supabase dashboard
3. Run the app and check console logs
4. Report back with the console output if issues persist