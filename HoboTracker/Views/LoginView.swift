import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Welcome to HoboTracker")
                .font(.title2.bold())

            Text("Sign in to sync your habits across devices. You can also continue offline.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Email/Password Section
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Button {
                    Task {
                        if isSignUp {
                            await appState.signUpWithEmail(email: email, password: password)
                        } else {
                            await appState.signInWithEmail(email: email, password: password)
                        }
                    }
                } label: {
                    Text(isSignUp ? "Sign Up with Email" : "Sign In with Email")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(appState.authService.isLoading || email.isEmpty || password.isEmpty)
                
                Button {
                    isSignUp.toggle()
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                }
            }
            
            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                Text("OR")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Button {
                Task {
                    await appState.signInWithGoogle()
                }
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Continue with Google")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
            .disabled(appState.authService.isLoading)

            Button {
                appState.allowOffline = true
            } label: {
                Text("Continue Offline")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)

            if appState.authService.isLoading {
                ProgressView()
                    .padding(.top, 8)
            }
            
            if let errorMessage = appState.lastSyncError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .onAppear {
            print("🔐 LoginView: View appeared")
            print("🔐 LoginView: isAuthenticated = \(appState.isAuthenticated)")
            print("🔐 LoginView: allowOffline = \(appState.allowOffline)")
        }
    }
}
