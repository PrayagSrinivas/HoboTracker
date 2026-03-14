# How to Find Your Supabase Anon Key

## You're Currently Looking At: Data API Integration Page
That page shows the REST endpoint, but not the API keys.

## Where to Find the Anon Key

### Method 1: Project Settings > API
1. In the left sidebar, click the **⚙️ Settings** icon (gear icon at the bottom)
2. Click **"API"** in the Settings menu
3. You'll see a section called **"Project API keys"**
4. Look for **"anon public"** key - this is what you need!

**Direct URL for your project:**
```
https://app.supabase.com/project/jofuyylrfznqvhuehvjk/settings/api
```

### What It Looks Like
The anon key is a long JWT token that starts with `eyJ` and looks like:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvZnV5eWxyZnpucXZodWVodmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3MTc0MDUsImV4cCI6MjAyMjI5MzQwNX0.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## Screenshot Guide

When you're on the right page, you should see:

```
Project API keys
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project URL
https://jofuyylrfznqvhuehvjk.supabase.co

anon public                                    [👁️] [📋 Copy]
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

service_role secret                            [👁️] [📋 Copy]
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**YOU NEED**: The `anon public` key (NOT the service_role!)

## Steps to Copy It

1. Go to Settings > API (use the direct URL above)
2. Find the "anon public" key
3. Click the **📋 Copy** button next to it
4. Paste it into `SupabaseConfig.swift`

## Where to Paste It

Open: `/Users/srinivasprayagsahu/Documents/HoboTracker/HoboTracker/Services/SupabaseConfig.swift`

Replace this line:
```swift
static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvZnV5eWxyZnpucXZodWVodmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3MTc0MDUsImV4cCI6MjAyMjI5MzQwNX0.YOUR_ACTUAL_ANON_KEY_HERE"
```

With:
```swift
static let anonKey = "PASTE_YOUR_COPIED_KEY_HERE"
```

## Alternative: Use Command Line
If you have Supabase CLI installed:
```bash
supabase status
```
This will show your keys in the terminal.

## Still Can't Find It?

### Navigation Path:
1. Go to: https://app.supabase.com
2. Select your project: "HoboTracker"
3. Left sidebar (bottom) → Click ⚙️ **Settings**
4. In settings menu → Click **"API"**
5. Scroll down to "Project API keys"
6. Copy the **"anon public"** key

### Visual Clues You're in the Right Place:
- Page title should say "API Settings" or "Project API keys"
- You'll see TWO keys: `anon public` and `service_role`
- There will be a warning about the service_role key being sensitive
- Each key has an eye icon (👁️) to reveal and a copy button (📋)

## Security Note
⚠️ The `anon public` key is safe to use in your iOS app - it's designed for client-side use.
⚠️ Do NOT use the `service_role` key in your app - it's for server-side only!

---

Once you copy the anon key, let me know and I'll help you paste it into the config file!