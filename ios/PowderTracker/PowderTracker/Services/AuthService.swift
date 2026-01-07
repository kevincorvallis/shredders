import Foundation
import Supabase
import Auth
import AuthenticationServices

@MainActor
@Observable
class AuthService {
    static let shared = AuthService()

    private let supabase: SupabaseClient

    var currentUser: Supabase.User?
    var userProfile: UserProfile?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false
    var error: String?

    private init() {
        supabase = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )

        Task {
            await checkSession()
            await listenForAuthChanges()
        }
    }

    // MARK: - Session Management

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            if let user = currentUser {
                await fetchUserProfile(userId: user.id.uuidString)
            }
        } catch {
            // No active session, user is not logged in
            currentUser = nil
            userProfile = nil
        }
    }

    private func listenForAuthChanges() async {
        for await (event, session) in supabase.auth.authStateChanges {
            switch event {
            case .signedIn:
                if let session = session {
                    currentUser = session.user
                    await fetchUserProfile(userId: session.user.id.uuidString)
                }
            case .signedOut:
                currentUser = nil
                userProfile = nil
            default:
                break
            }
        }
    }

    // MARK: - Authentication Methods

    func signUp(email: String, password: String, username: String, displayName: String?) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Create auth user
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "username": .string(username),
                    "display_name": .string(displayName ?? username)
                ]
            )

            let user = response.user

            // Create user profile in database
            struct UserInsert: Encodable {
                let auth_user_id: String
                let username: String
                let email: String
                let display_name: String
            }

            let profile = UserInsert(
                auth_user_id: user.id.uuidString,
                username: username,
                email: email,
                display_name: displayName ?? username
            )

            try await supabase
                .from("users")
                .insert(profile)
                .execute()

            currentUser = user
            await fetchUserProfile(userId: user.id.uuidString)

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            currentUser = session.user

            // Update last login time
            try await supabase
                .from("users")
                .update(["last_login_at": ISO8601DateFormatter().string(from: Date())])
                .eq("auth_user_id", value: session.user.id.uuidString)
                .execute()

            await fetchUserProfile(userId: session.user.id.uuidString)

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            currentUser = session.user

            // Check if user profile exists, create if not
            let existingProfile = try? await supabase
                .from("users")
                .select()
                .eq("auth_user_id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value as UserProfile?

            if existingProfile == nil {
                // Create user profile for new Apple sign-in user
                struct UserInsert: Encodable {
                    let auth_user_id: String
                    let username: String
                    let email: String
                    let display_name: String
                }

                let profile = UserInsert(
                    auth_user_id: session.user.id.uuidString,
                    username: session.user.email?.components(separatedBy: "@").first ?? "user_\(session.user.id.uuidString.prefix(8))",
                    email: session.user.email ?? "",
                    display_name: session.user.userMetadata["full_name"]?.value as? String ?? "Apple User"
                )

                try await supabase
                    .from("users")
                    .insert(profile)
                    .execute()
            }

            await fetchUserProfile(userId: session.user.id.uuidString)

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func signOut() async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            try await supabase.auth.signOut()
            currentUser = nil
            userProfile = nil
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Profile Management

    func fetchUserProfile(userId: String) async {
        do {
            let response: UserProfile = try await supabase
                .from("users")
                .select()
                .eq("auth_user_id", value: userId)
                .single()
                .execute()
                .value

            userProfile = response
        } catch {
            print("Failed to fetch user profile: \(error)")
        }
    }

    func updateProfile(displayName: String?, bio: String?, homeMountainId: String?) async throws {
        guard let userId = currentUser?.id.uuidString else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        struct UserUpdate: Encodable {
            let display_name: String?
            let bio: String?
            let home_mountain_id: String?
            let updated_at: String
        }

        let updates = UserUpdate(
            display_name: displayName,
            bio: bio,
            home_mountain_id: homeMountainId,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        do {
            try await supabase
                .from("users")
                .update(updates)
                .eq("auth_user_id", value: userId)
                .execute()

            await fetchUserProfile(userId: userId)

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
}
