import Foundation
import Supabase
import Auth
import AuthenticationServices

/// Authentication error types
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case emailNotVerified
    case networkError(Error)
    case serverError(String)
    case tokenStorageFailed
    case noRefreshToken
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailNotVerified:
            return "Please verify your email address"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .tokenStorageFailed:
            return "Failed to store authentication tokens"
        case .noRefreshToken:
            return "No refresh token available"
        case .sessionExpired:
            return "Your session has expired. Please sign in again"
        }
    }
}

@MainActor
@Observable
class AuthService {
    static let shared = AuthService()

    private let supabase = SupabaseClientManager.shared.client
    private let apiBaseURL = AppConfig.apiBaseURL

    var currentUser: Supabase.User?
    var userProfile: UserProfile?
    var isAuthenticated: Bool { currentUser != nil || KeychainHelper.hasValidTokens() }
    var isLoading = false
    var error: String?

    // MARK: - Retry Configuration
    private let maxRetries = 3
    private let baseRetryDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds

    // MARK: - Cached User (Phase 2 optimization)
    private(set) var cachedUserId: String?
    private(set) var cachedUser: Supabase.User?

    // MARK: - Auth Listener (Phase 7 optimization)
    private var authListenerTask: Task<Void, Never>?

    /// Check if running in UI testing mode with state reset
    private static var shouldResetState: Bool {
        ProcessInfo.processInfo.arguments.contains("RESET_STATE")
    }

    private init() {
        // CRITICAL: Clear tokens BEFORE any auth checks when UI testing with RESET_STATE
        if Self.shouldResetState {
            KeychainHelper.clearTokens()
        }

        // Skip session restoration during UI tests with RESET_STATE
        guard !Self.shouldResetState else { return }

        Task {
            await checkSession()
            await cacheCurrentUser()

            // Auto-login in DEBUG builds if credentials are provided via environment variables
            #if DEBUG
            await performDebugAutoLogin()
            #endif

            startAuthListener()
        }
    }

    /// Start listening for auth state changes (Phase 7)
    private func startAuthListener() {
        authListenerTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.listenForAuthChanges()
        }
    }

    /// Stop the auth listener to prevent memory leaks (Phase 7)
    func stopAuthListener() {
        authListenerTask?.cancel()
        authListenerTask = nil
    }

    // MARK: - Cached User Access (Phase 2)

    /// Cache the current user for fast synchronous access
    func cacheCurrentUser() async {
        do {
            let user = try await supabase.auth.session.user
            cachedUserId = user.id.uuidString
            cachedUser = user
        } catch {
            cachedUserId = nil
            cachedUser = nil
        }
    }

    /// Fast synchronous access to current user ID
    func getCurrentUserId() -> String? {
        return cachedUserId
    }

    /// Fast synchronous access to current user
    func getCurrentUser() -> Supabase.User? {
        return cachedUser
    }

    // MARK: - Debug Auto-Login

    #if DEBUG
    /// Automatically logs in using environment variables for development convenience.
    /// Set DEBUG_EMAIL and DEBUG_PASSWORD in your Xcode scheme's environment variables.
    private func performDebugAutoLogin() async {
        // Skip if already authenticated
        guard !isAuthenticated else { return }

        // Check for debug credentials in environment variables
        guard let email = ProcessInfo.processInfo.environment["DEBUG_EMAIL"],
              let password = ProcessInfo.processInfo.environment["DEBUG_PASSWORD"],
              !email.isEmpty, !password.isEmpty else {
            return
        }

        print("🔐 [DEBUG] Auto-login enabled, signing in as \(email)...")

        do {
            try await signInViaBackend(email: email, password: password)
            print("🔐 [DEBUG] Auto-login successful!")
        } catch {
            print("🔐 [DEBUG] Auto-login failed: \(error.localizedDescription)")
        }
    }
    #endif

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
                    cachedUserId = session.user.id.uuidString
                    cachedUser = session.user
                    await fetchUserProfile(userId: session.user.id.uuidString)
                }
            case .signedOut:
                currentUser = nil
                userProfile = nil
                cachedUserId = nil
                cachedUser = nil
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

        // Clear any cached tokens from previous user session
        EventService.clearCachedToken()

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
                .update(["last_login_at": DateFormatters.iso8601.string(from: Date())])
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

        // Clear any cached tokens from previous user session
        EventService.clearCachedToken()

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

            // Store tokens in Keychain so other services can access them
            // This ensures EventService, LikeService, etc. can authenticate
            do {
                try KeychainHelper.saveTokens(
                    accessToken: session.accessToken,
                    refreshToken: session.refreshToken,
                    expiresIn: session.expiresAt - Date().timeIntervalSince1970
                )
            } catch {
                #if DEBUG
                print("Warning: Failed to store Apple Sign In tokens in Keychain: \(error)")
                #endif
                // Continue even if token storage fails - Supabase session is still valid
            }

            // Check if user profile exists, create if not
            #if DEBUG
            print("🍎 Apple Sign In: Checking for existing profile for userId: \(session.user.id.uuidString)")
            #endif

            var profileExists = false
            do {
                let existingProfile: UserProfile = try await supabase
                    .from("users")
                    .select()
                    .eq("auth_user_id", value: session.user.id.uuidString)
                    .single()
                    .execute()
                    .value
                profileExists = true
                #if DEBUG
                print("✅ Apple Sign In: Found existing profile for user: \(existingProfile.displayName ?? "unknown")")
                #endif
            } catch {
                #if DEBUG
                print("ℹ️ Apple Sign In: No existing profile found, will create one. Error: \(error)")
                #endif
            }

            if !profileExists {
                // Create user profile for new Apple sign-in user
                struct UserInsert: Encodable {
                    let auth_user_id: String
                    let username: String
                    let email: String
                    let display_name: String
                }

                let username = session.user.email?.components(separatedBy: "@").first ?? "user_\(session.user.id.uuidString.prefix(8))"
                let displayName = session.user.userMetadata["full_name"]?.value as? String ?? "Apple User"

                let profile = UserInsert(
                    auth_user_id: session.user.id.uuidString,
                    username: username,
                    email: session.user.email ?? "",
                    display_name: displayName
                )

                #if DEBUG
                print("🍎 Apple Sign In: Creating new profile - username: \(username), displayName: \(displayName)")
                #endif

                do {
                    try await supabase
                        .from("users")
                        .insert(profile)
                        .execute()
                    #if DEBUG
                    print("✅ Apple Sign In: Profile created successfully")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ Apple Sign In: Failed to create profile: \(error)")
                    #endif
                    // Don't throw here - let the user continue, but they won't have a profile
                    // The onboarding will fail later, but at least they're signed in
                }
            }

            await fetchUserProfile(userId: session.user.id.uuidString)

            #if DEBUG
            print("🍎 Apple Sign In complete. userProfile exists: \(userProfile != nil)")
            #endif

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
            // Sign out from Supabase
            try await supabase.auth.signOut()

            // Clear JWT tokens from Keychain
            KeychainHelper.clearTokens()

            // Clear all cached data including EventService token cache
            // CRITICAL: This must be called to prevent token reuse between users
            EventService.clearAllCaches()

            // Clear cached user (Phase 2)
            currentUser = nil
            userProfile = nil
            cachedUserId = nil
            cachedUser = nil

            // Note: Don't stop auth listener here - it will handle the signedOut event
            // and continue listening for future sign-ins
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Backend API Authentication

    /// Sign in using the backend API (recommended)
    /// Returns JWT tokens for authenticated API access
    func signInViaBackend(email: String, password: String) async throws {
        isLoading = true
        error = nil

        // Clear any cached tokens from previous user session BEFORE signing in
        // This prevents token reuse between different user accounts
        EventService.clearCachedToken()

        defer { isLoading = false }

        struct LoginRequest: Encodable {
            let email: String
            let password: String
        }

        struct LoginResponse: Decodable {
            let user: UserResponse
            let accessToken: String
            let refreshToken: String
            let message: String?

            struct UserResponse: Decodable {
                let id: String
                let email: String?
            }
        }

        do {
            guard let url = URL(string: "\(apiBaseURL)/auth/login") else {
                throw AuthError.networkError(URLError(.badURL))
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(LoginRequest(email: email, password: password))

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError(URLError(.badServerResponse))
            }

            if httpResponse.statusCode == 401 {
                throw AuthError.invalidCredentials
            }

            if httpResponse.statusCode == 403 {
                // Check for email verification error
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   errorData["error"]?.contains("email_not_confirmed") == true {
                    throw AuthError.emailNotVerified
                }
                throw AuthError.invalidCredentials
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                    throw AuthError.serverError(errorMessage)
                }
                throw AuthError.serverError("Login failed with status \(httpResponse.statusCode)")
            }

            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)

            // Store tokens securely
            do {
                try KeychainHelper.saveTokens(
                    accessToken: loginResponse.accessToken,
                    refreshToken: loginResponse.refreshToken,
                    expiresIn: 15 * 60 // 15 minutes
                )
            } catch {
                throw AuthError.tokenStorageFailed
            }

            // Also sign in with Supabase for real-time features (non-blocking)
            // This is optional - JWT tokens are the primary auth mechanism
            let supabaseClient = self.supabase
            Task {
                do {
                    try await supabaseClient.auth.signIn(email: email, password: password)
                } catch {
                    // Supabase sign-in failure doesn't block login
                    // Real-time features will be unavailable
                    #if DEBUG
                    print("Supabase sign-in failed (non-critical): \(error)")
                    #endif
                }
            }

            // Fetch user profile
            await fetchUserProfile(userId: loginResponse.user.id)

        } catch let authError as AuthError {
            self.error = authError.localizedDescription
            throw authError
        } catch {
            self.error = error.localizedDescription
            throw AuthError.networkError(error)
        }
    }

    /// Sign up using the backend API
    func signUpViaBackend(email: String, password: String, username: String, displayName: String?) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        struct SignupRequest: Encodable {
            let email: String
            let password: String
            let username: String
            let displayName: String?
        }

        struct SignupResponse: Decodable {
            let user: UserResponse
            let accessToken: String?
            let refreshToken: String?
            let needsEmailVerification: Bool?
            let message: String?

            struct UserResponse: Decodable {
                let id: String
                let email: String?
            }
        }

        do {
            guard let url = URL(string: "\(apiBaseURL)/auth/signup") else {
                throw AuthError.networkError(URLError(.badURL))
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let signupRequest = SignupRequest(
                email: email,
                password: password,
                username: username,
                displayName: displayName ?? username
            )
            request.httpBody = try JSONEncoder().encode(signupRequest)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError(URLError(.badServerResponse))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to decode error with details
                struct ErrorResponse: Decodable {
                    let error: String
                    let details: [String]?
                }
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    let message = errorResponse.details?.joined(separator: ", ") ?? errorResponse.error
                    throw AuthError.serverError(message)
                }
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                    throw AuthError.serverError(errorMessage)
                }
                throw AuthError.serverError("Signup failed with status \(httpResponse.statusCode)")
            }

            let signupResponse = try JSONDecoder().decode(SignupResponse.self, from: data)

            // Check if email verification is required
            if signupResponse.needsEmailVerification == true {
                // Account created but user needs to verify email before signing in
                throw AuthError.emailNotVerified
            }

            // Ensure we have tokens (email verification not required)
            guard let accessToken = signupResponse.accessToken,
                  let refreshToken = signupResponse.refreshToken else {
                throw AuthError.serverError("Signup succeeded but no tokens received")
            }

            // Store tokens securely
            do {
                try KeychainHelper.saveTokens(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresIn: 15 * 60
                )
            } catch {
                throw AuthError.tokenStorageFailed
            }

            // Create Supabase session for real-time features (non-blocking)
            // Backend signup already creates the user - just sign in to get a local session
            let supabaseClient = self.supabase
            Task { [weak self] in
                do {
                    let session = try await supabaseClient.auth.signIn(
                        email: email,
                        password: password
                    )
                    await MainActor.run {
                        self?.currentUser = session.user
                    }
                } catch {
                    // Supabase sign-in failure doesn't block signup
                    // User is already created via backend
                    #if DEBUG
                    print("Supabase sign-in failed (non-critical): \(error)")
                    #endif
                }
            }

            await fetchUserProfile(userId: signupResponse.user.id)

        } catch let authError as AuthError {
            self.error = authError.localizedDescription
            throw authError
        } catch {
            self.error = error.localizedDescription
            throw AuthError.networkError(error)
        }
    }

    /// Refresh tokens using the backend API
    func refreshTokens() async throws {
        guard let refreshToken = KeychainHelper.getRefreshToken() else {
            throw AuthError.noRefreshToken
        }

        struct RefreshRequest: Encodable {
            let refreshToken: String
        }

        struct RefreshResponse: Decodable {
            let accessToken: String
            let refreshToken: String
        }

        guard let url = URL(string: "\(apiBaseURL)/auth/refresh") else {
            throw AuthError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RefreshRequest(refreshToken: refreshToken))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            KeychainHelper.clearTokens()
            throw AuthError.sessionExpired
        }

        let refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)

        try KeychainHelper.saveTokens(
            accessToken: refreshResponse.accessToken,
            refreshToken: refreshResponse.refreshToken,
            expiresIn: 15 * 60
        )
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
            #if DEBUG
            print("Failed to fetch user profile: \(error)")
            #endif
        }
    }

    func updateProfile(displayName: String?, bio: String?, homeMountainId: String?, avatarUrl: String? = nil) async throws {
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
            let avatar_url: String?
            let updated_at: String
        }

        let updates = UserUpdate(
            display_name: displayName,
            bio: bio,
            home_mountain_id: homeMountainId,
            avatar_url: avatarUrl,
            updated_at: DateFormatters.iso8601.string(from: Date())
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

    // MARK: - Onboarding

    /// Returns true if the current user needs to complete onboarding
    var needsOnboarding: Bool {
        guard let profile = userProfile else { return false }
        return profile.needsOnboarding
    }

    /// Retry helper for network operations with exponential backoff
    @discardableResult
    private func withRetry<T>(operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Don't retry for non-transient errors
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .timedOut, .networkConnectionLost:
                        // These are transient - worth retrying
                        break
                    default:
                        throw error
                    }
                }

                // Exponential backoff: 1s, 2s, 4s
                if attempt < maxRetries - 1 {
                    let delay = baseRetryDelay * UInt64(1 << attempt)
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }

        throw lastError ?? NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation failed after retries"])
    }

    /// Update user profile with onboarding data
    func updateOnboardingProfile(_ profile: OnboardingProfile) async throws {
        guard let userId = currentUser?.id.uuidString ?? userProfile?.authUserId else {
            #if DEBUG
            print("❌ updateOnboardingProfile: No userId available")
            print("   currentUser: \(currentUser != nil ? "exists" : "nil")")
            print("   userProfile: \(userProfile != nil ? "exists" : "nil")")
            #endif
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        // First, ensure user profile exists in database
        // This handles edge cases where Apple Sign In didn't create the profile
        if userProfile == nil {
            #if DEBUG
            print("⚠️ updateOnboardingProfile: No userProfile found, attempting to create one for userId: \(userId)")
            #endif

            // Try to fetch first - profile might exist but not be loaded
            await fetchUserProfile(userId: userId)

            // If still nil, create the profile
            if userProfile == nil {
                #if DEBUG
                print("📝 updateOnboardingProfile: Profile not found after fetch, creating new profile...")
                #endif

                struct UserInsert: Encodable {
                    let auth_user_id: String
                    let username: String
                    let email: String
                    let display_name: String
                }

                let email = currentUser?.email ?? ""
                let username = email.components(separatedBy: "@").first ?? "user_\(userId.prefix(8))"

                let newProfile = UserInsert(
                    auth_user_id: userId,
                    username: username,
                    email: email,
                    display_name: profile.displayName ?? username
                )

                do {
                    try await supabase
                        .from("users")
                        .insert(newProfile)
                        .execute()
                    #if DEBUG
                    print("✅ updateOnboardingProfile: Created missing user profile")
                    #endif

                    // Fetch the profile we just created
                    await fetchUserProfile(userId: userId)
                } catch {
                    #if DEBUG
                    print("❌ updateOnboardingProfile: Failed to create user profile: \(error)")
                    #endif
                    // Profile might already exist (race condition) - try fetching again
                    await fetchUserProfile(userId: userId)
                }
            }

            // Final check - if we still don't have a profile, something is wrong
            if userProfile == nil {
                #if DEBUG
                print("❌ updateOnboardingProfile: Still no profile after creation attempt")
                #endif
                throw NSError(domain: "AuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not create user profile. Please try signing in again."])
            }
        }

        struct OnboardingUpdate: Encodable {
            let display_name: String?
            let bio: String?
            let avatar_url: String?
            let experience_level: String?
            let preferred_terrain: [String]
            let season_pass_type: String?
            let home_mountain_id: String?
            let updated_at: String
        }

        let updates = OnboardingUpdate(
            display_name: profile.displayName,
            bio: profile.bio,
            avatar_url: profile.avatarUrl,
            experience_level: profile.experienceLevel?.rawValue,
            preferred_terrain: profile.preferredTerrain.map { $0.rawValue },
            season_pass_type: profile.seasonPassType?.rawValue,
            home_mountain_id: profile.homeMountainId,
            updated_at: DateFormatters.iso8601.string(from: Date())
        )

        #if DEBUG
        print("📝 updateOnboardingProfile called for userId: \(userId)")
        print("   Profile data: displayName=\(profile.displayName ?? "nil"), bio=\(profile.bio ?? "nil")")
        print("   Current user exists: \(currentUser != nil), userProfile exists: \(userProfile != nil)")
        #endif

        do {
            try await withRetry {
                try await self.supabase
                    .from("users")
                    .update(updates)
                    .eq("auth_user_id", value: userId)
                    .execute()
            }

            #if DEBUG
            print("✅ updateOnboardingProfile succeeded")
            #endif

            await fetchUserProfile(userId: userId)

        } catch {
            #if DEBUG
            print("❌ updateOnboardingProfile failed: \(error)")
            #endif
            self.error = error.localizedDescription
            throw error
        }
    }

    /// Mark onboarding as complete
    func completeOnboarding() async throws {
        guard let userId = currentUser?.id.uuidString ?? userProfile?.authUserId else {
            #if DEBUG
            print("❌ completeOnboarding: No user logged in")
            print("   currentUser: \(currentUser != nil ? "exists" : "nil")")
            print("   userProfile: \(userProfile != nil ? "exists" : "nil")")
            #endif
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        #if DEBUG
        print("📝 completeOnboarding called for userId: \(userId)")
        #endif

        isLoading = true
        error = nil

        defer { isLoading = false }

        struct CompletionUpdate: Encodable {
            let has_completed_onboarding: Bool
            let onboarding_completed_at: String
            let updated_at: String
        }

        let now = DateFormatters.iso8601.string(from: Date())
        let updates = CompletionUpdate(
            has_completed_onboarding: true,
            onboarding_completed_at: now,
            updated_at: now
        )

        do {
            try await withRetry {
                try await self.supabase
                    .from("users")
                    .update(updates)
                    .eq("auth_user_id", value: userId)
                    .execute()
            }

            #if DEBUG
            print("✅ completeOnboarding succeeded")
            #endif

            await fetchUserProfile(userId: userId)

        } catch {
            #if DEBUG
            print("❌ completeOnboarding failed: \(error)")
            #endif
            self.error = error.localizedDescription
            throw error
        }
    }

    /// Skip onboarding (user can complete later)
    func skipOnboarding() async throws {
        guard let userId = currentUser?.id.uuidString ?? userProfile?.authUserId else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        struct SkipUpdate: Encodable {
            let onboarding_skipped_at: String
            let updated_at: String
        }

        let now = DateFormatters.iso8601.string(from: Date())
        let updates = SkipUpdate(
            onboarding_skipped_at: now,
            updated_at: now
        )

        do {
            try await withRetry {
                try await self.supabase
                    .from("users")
                    .update(updates)
                    .eq("auth_user_id", value: userId)
                    .execute()
            }

            await fetchUserProfile(userId: userId)

        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
}
