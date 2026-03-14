import AuthenticationServices
import Combine
import Supabase
import SwiftUI
import UIKit

@MainActor
final class AuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published private(set) var session: Session?
    @Published private(set) var user: User?
    @Published var isLoading = false

    private let client: SupabaseClient
    private var webAuthSession: ASWebAuthenticationSession?

    override init() {
        client = SupabaseClientProvider.shared.client
        super.init()
    }

    var isAuthenticated: Bool {
        user != nil
    }

    var userId: String? {
        user?.id.uuidString.lowercased()
    }

    func loadSession() async {
        do {
            let session = try await client.auth.session
            self.session = session
            self.user = session.user
        } catch {
            self.session = nil
            self.user = nil
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        print("🔐 AuthService: Starting email sign-in for: \(email)")
        
        // Using the correct Supabase Auth API
        try await client.auth.signIn(email: email, password: password)
        
        // Reload the session after sign in
        let session = try await client.auth.session
        self.session = session
        self.user = session.user
        
        print("✅ AuthService: Email sign-in successful! User ID: \(session.user.id)")
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        print("🔐 AuthService: Starting email sign-up for: \(email)")
        
        // Using the correct Supabase Auth API
        try await client.auth.signUp(email: email, password: password)
        
        // Try to reload the session
        do {
            let session = try await client.auth.session
            self.session = session
            self.user = session.user
            print("✅ AuthService: Email sign-up successful! User ID: \(session.user.id)")
        } catch {
            // Email confirmation might be required
            print("📧 AuthService: Sign-up successful! Please check your email to confirm your account")
        }
    }
    
    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }

        print("🔐 AuthService: Starting Google sign-in...")
        
        let authURL = try await client.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: SupabaseConfig.redirectURL
        )
        
        print("🔐 AuthService: Auth URL generated: \(authURL)")

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            webAuthSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: SupabaseConfig.callbackScheme
            ) { url, error in
                if let error {
                    print("❌ AuthService: Web auth session error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                guard let url else {
                    print("❌ AuthService: No callback URL received")
                    continuation.resume(throwing: URLError(.badURL))
                    return
                }
                print("🔐 AuthService: Callback URL received: \(url)")
                continuation.resume(returning: url)
            }
            webAuthSession?.presentationContextProvider = self
            webAuthSession?.prefersEphemeralWebBrowserSession = true
            webAuthSession?.start()
        }

        print("🔐 AuthService: Exchanging callback URL for session...")
        let session = try await client.auth.session(from: callbackURL)
        self.session = session
        self.user = session.user
        print("✅ AuthService: Sign-in successful! User ID: \(session.user.id)")
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            // ignore sign-out errors
        }
        session = nil
        user = nil
    }

    var createdAt: Date? {
        user?.createdAt
    }

    var fullName: String? {
        if let raw = user?.userMetadata["full_name"]?.value {
            return String(describing: raw)
        }
        return nil
    }

    var email: String? {
        user?.email
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               let window = windowScene.windows.first {
                return window
            }
        }
        return ASPresentationAnchor()
    }
}
