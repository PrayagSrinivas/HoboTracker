import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.authService.fullName ?? "Unknown")
                                .font(.headline)
                            if let email = appState.authService.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("Account") {
                    if let createdAt = appState.authService.createdAt {
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                    }
                    if let userId = appState.authService.userId {
                        HStack {
                            Text("User ID")
                            Spacer()
                            Text(userId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let lastSyncError = appState.lastSyncError {
                    Section("Sync Status") {
                        Text(lastSyncError)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            await appState.signOut()
                        }
                    } label: {
                        Text("Log Out")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
