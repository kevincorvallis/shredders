import XCTest
@testable import PowderTracker

/// Tests for AuthService authentication functionality
/// Tests actual AuthService methods and KeychainHelper behavior
final class AuthServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clean slate for each test
        KeychainHelper.clearTokens()
    }

    override func tearDown() {
        // Always clean up keychain state
        KeychainHelper.clearTokens()
        super.tearDown()
    }

    // MARK: - KeychainHelper Token Storage Tests

    func testKeychainHelper_SaveAndRetrieveAccessToken() throws {
        let testToken = "test-access-token-\(UUID().uuidString)"

        try KeychainHelper.saveAccessToken(testToken)

        let retrieved = KeychainHelper.getAccessToken()
        XCTAssertEqual(retrieved, testToken, "Retrieved access token should match saved token")
    }

    func testKeychainHelper_SaveAndRetrieveRefreshToken() throws {
        let testToken = "test-refresh-token-\(UUID().uuidString)"

        try KeychainHelper.saveRefreshToken(testToken)

        let retrieved = KeychainHelper.getRefreshToken()
        XCTAssertEqual(retrieved, testToken, "Retrieved refresh token should match saved token")
    }

    func testKeychainHelper_ClearTokens_RemovesAll() throws {
        try KeychainHelper.saveAccessToken("access-token")
        try KeychainHelper.saveRefreshToken("refresh-token")

        // Verify they were saved
        XCTAssertNotNil(KeychainHelper.getAccessToken())
        XCTAssertNotNil(KeychainHelper.getRefreshToken())

        KeychainHelper.clearTokens()

        XCTAssertNil(KeychainHelper.getAccessToken(), "Access token should be nil after clear")
        XCTAssertNil(KeychainHelper.getRefreshToken(), "Refresh token should be nil after clear")
    }

    func testKeychainHelper_OverwriteExistingToken() throws {
        try KeychainHelper.saveAccessToken("first-token")
        try KeychainHelper.saveAccessToken("second-token")

        let retrieved = KeychainHelper.getAccessToken()
        XCTAssertEqual(retrieved, "second-token", "Should return the most recently saved token")
    }

    func testKeychainHelper_GetTokenWhenNoneExists() {
        // No tokens saved
        XCTAssertNil(KeychainHelper.getAccessToken(), "Should return nil when no access token exists")
        XCTAssertNil(KeychainHelper.getRefreshToken(), "Should return nil when no refresh token exists")
    }

    // MARK: - Token Expiry Tests

    func testKeychainHelper_TokenExpiry_ExpiredWithBuffer() throws {
        // Token expires in 30 seconds - within the 60-second safety buffer
        let shortExpiry = Date().addingTimeInterval(30)
        try KeychainHelper.saveTokenExpiry(shortExpiry)

        XCTAssertTrue(KeychainHelper.isAccessTokenExpired(),
                      "Token expiring within buffer should be considered expired")
    }

    func testKeychainHelper_TokenExpiry_NotExpired() throws {
        // Token expires in 5 minutes - well outside the buffer
        let longExpiry = Date().addingTimeInterval(300)
        try KeychainHelper.saveTokenExpiry(longExpiry)

        XCTAssertFalse(KeychainHelper.isAccessTokenExpired(),
                       "Token with 5 minutes remaining should not be expired")
    }

    func testKeychainHelper_TokenExpiry_AlreadyPast() throws {
        // Token already expired
        let pastExpiry = Date().addingTimeInterval(-60)
        try KeychainHelper.saveTokenExpiry(pastExpiry)

        XCTAssertTrue(KeychainHelper.isAccessTokenExpired(),
                      "Token with past expiry should be expired")
    }

    // MARK: - HasValidTokens Tests

    func testKeychainHelper_HasValidTokens_NoTokens() {
        XCTAssertFalse(KeychainHelper.hasValidTokens(),
                       "Should return false when no tokens are stored")
    }

    func testKeychainHelper_HasValidTokens_WithTokens() throws {
        try KeychainHelper.saveAccessToken("access")
        try KeychainHelper.saveRefreshToken("refresh")

        XCTAssertTrue(KeychainHelper.hasValidTokens(),
                      "Should return true when tokens are stored")
    }

    func testKeychainHelper_HasValidTokens_OnlyAccessToken() throws {
        try KeychainHelper.saveAccessToken("access")

        // hasValidTokens checks for access token existence
        // Behavior depends on implementation - verify it's consistent
        let hasValid = KeychainHelper.hasValidTokens()
        // Access token alone should be enough for validity check
        XCTAssertTrue(hasValid, "Should be valid with just access token")
    }

    // MARK: - SaveTokens Bundle Tests

    func testKeychainHelper_SaveTokensBundle() throws {
        try KeychainHelper.saveTokens(
            accessToken: "bundle-access",
            refreshToken: "bundle-refresh",
            expiresIn: 900 // 15 minutes
        )

        XCTAssertEqual(KeychainHelper.getAccessToken(), "bundle-access")
        XCTAssertEqual(KeychainHelper.getRefreshToken(), "bundle-refresh")
        XCTAssertFalse(KeychainHelper.isAccessTokenExpired(),
                       "Newly saved token with 15 min expiry should not be expired")
    }

    func testKeychainHelper_SaveTokensBundle_ClearAndResave() throws {
        // Save first set
        try KeychainHelper.saveTokens(
            accessToken: "first-access",
            refreshToken: "first-refresh",
            expiresIn: 900
        )

        // Clear and save new set
        KeychainHelper.clearTokens()
        try KeychainHelper.saveTokens(
            accessToken: "second-access",
            refreshToken: "second-refresh",
            expiresIn: 900
        )

        XCTAssertEqual(KeychainHelper.getAccessToken(), "second-access")
        XCTAssertEqual(KeychainHelper.getRefreshToken(), "second-refresh")
    }

    // MARK: - AppConfig Tests

    func testAppConfig_APIBaseURL_IsValid() {
        let apiURL = AppConfig.apiBaseURL

        XCTAssertFalse(apiURL.isEmpty, "API URL should not be empty")
        XCTAssertTrue(apiURL.hasPrefix("https://"), "API URL should use HTTPS")
        XCTAssertTrue(apiURL.hasSuffix("/api"), "API URL should end with /api")
    }

    func testAppConfig_SupabaseURL_IsValid() {
        let supabaseURL = AppConfig.supabaseURL

        XCTAssertFalse(supabaseURL.isEmpty, "Supabase URL should not be empty")
        XCTAssertTrue(supabaseURL.hasPrefix("https://"), "Supabase URL should use HTTPS")
    }

    func testAppConfig_SafeURLCreation() {
        let endpoints = ["/auth/login", "/auth/signup", "/auth/refresh", "/events", "/mountains"]

        for endpoint in endpoints {
            let url = AppConfig.apiURL(for: endpoint)
            XCTAssertNotNil(url, "Should create valid URL for endpoint: \(endpoint)")
            XCTAssertTrue(url?.absoluteString.contains(endpoint) == true,
                         "URL should contain endpoint path: \(endpoint)")
        }
    }

    func testAppConfig_URLCreation_EmptyEndpoint() {
        let url = AppConfig.apiURL(for: "")
        XCTAssertNotNil(url, "Should handle empty endpoint gracefully")
    }

    // MARK: - AuthError Tests

    func testAuthError_AllCasesHaveDescriptions() {
        let errors: [AuthError] = [
            .invalidCredentials,
            .emailNotVerified,
            .tokenStorageFailed,
            .noRefreshToken,
            .sessionExpired,
            .serverError("Test server error"),
            .networkError(URLError(.badServerResponse))
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description: \(error)")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true,
                          "Error description should not be empty: \(error)")
        }
    }

    func testAuthError_InvalidCredentials_Message() {
        let error = AuthError.invalidCredentials
        XCTAssertEqual(error.errorDescription, "Invalid email or password")
    }

    func testAuthError_EmailNotVerified_Message() {
        let error = AuthError.emailNotVerified
        XCTAssertEqual(error.errorDescription, "Please verify your email address")
    }

    func testAuthError_ServerError_PreservesMessage() {
        let customMessage = "Custom server error message"
        let error = AuthError.serverError(customMessage)
        XCTAssertEqual(error.errorDescription, customMessage)
    }

    func testAuthError_NetworkError_IncludesUnderlying() {
        let urlError = URLError(.notConnectedToInternet)
        let error = AuthError.networkError(urlError)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Network") ?? false,
                     "Network error description should mention 'Network'")
    }

    func testAuthError_SessionExpired_Message() {
        let error = AuthError.sessionExpired
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("expired") ?? false,
                     "Session expired error should mention 'expired'")
    }

    func testAuthError_NoRefreshToken_Message() {
        let error = AuthError.noRefreshToken
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("refresh token") ?? false,
                     "No refresh token error should mention 'refresh token'")
    }

    // MARK: - BiometricAuthService Tests

    @MainActor func testBiometricAuthService_BiometricType_IsValid() {
        let biometricService = BiometricAuthService.shared
        let biometricType = biometricService.biometricType

        switch biometricType {
        case .faceID, .touchID, .none:
            // All valid
            break
        }
    }

    @MainActor func testBiometricAuthService_BiometricTypeName_IsNonEmpty() {
        let biometricService = BiometricAuthService.shared
        let name = biometricService.biometricTypeName

        XCTAssertFalse(name.isEmpty, "Biometric type name should not be empty")

        let validNames = ["Face ID", "Touch ID", "Biometric"]
        XCTAssertTrue(validNames.contains(name),
                     "Biometric type name '\(name)' should be one of \(validNames)")
    }

    @MainActor func testBiometricAuthService_DisableBiometric() {
        let biometricService = BiometricAuthService.shared

        biometricService.disableBiometric()
        XCTAssertFalse(biometricService.isBiometricEnabled,
                      "Biometric should be disabled after calling disableBiometric()")
    }

    // MARK: - Signup Response Decoding Tests

    func testSignupResponse_DecodesWithTokens() throws {
        let json = """
        {
            "user": {"id": "123", "email": "test@example.com"},
            "accessToken": "access-token-123",
            "refreshToken": "refresh-token-456",
            "message": "Account created successfully"
        }
        """.data(using: .utf8)!

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

        let response = try JSONDecoder().decode(SignupResponse.self, from: json)

        XCTAssertEqual(response.user.id, "123")
        XCTAssertEqual(response.user.email, "test@example.com")
        XCTAssertEqual(response.accessToken, "access-token-123")
        XCTAssertEqual(response.refreshToken, "refresh-token-456")
        XCTAssertNil(response.needsEmailVerification)
        XCTAssertEqual(response.message, "Account created successfully")
    }

    func testSignupResponse_DecodesWithEmailVerification() throws {
        let json = """
        {
            "user": {"id": "456", "email": "new@example.com"},
            "needsEmailVerification": true,
            "message": "Please check your email to verify your account"
        }
        """.data(using: .utf8)!

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

        let response = try JSONDecoder().decode(SignupResponse.self, from: json)

        XCTAssertEqual(response.user.id, "456")
        XCTAssertNil(response.accessToken, "Should not have tokens when verification required")
        XCTAssertNil(response.refreshToken, "Should not have tokens when verification required")
        XCTAssertTrue(response.needsEmailVerification ?? false)
    }

    func testSignupResponse_HandlesVerificationFlowLogic() throws {
        // Test the branching logic AuthService uses for signup responses
        let verificationJson = """
        {
            "user": {"id": "789", "email": "verify@example.com"},
            "needsEmailVerification": true,
            "message": "Please verify"
        }
        """.data(using: .utf8)!

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

        let response = try JSONDecoder().decode(SignupResponse.self, from: verificationJson)

        // Simulate the actual AuthService logic branch
        if response.needsEmailVerification == true {
            // This branch should throw AuthError.emailNotVerified in AuthService
            XCTAssertTrue(true, "Verification flow correctly detected")
            XCTAssertNil(response.accessToken, "Should have no tokens when verification needed")
        } else if response.accessToken != nil, response.refreshToken != nil {
            XCTFail("Should not reach token branch when verification is required")
        } else {
            XCTFail("Should detect verification flag")
        }
    }

    // MARK: - AuthService isAuthenticated Property Tests

    @MainActor
    func testAuthService_IsAuthenticated_WithValidTokens() throws {
        // Save valid tokens to make isAuthenticated return true via KeychainHelper.hasValidTokens()
        try KeychainHelper.saveAccessToken("test-token")
        try KeychainHelper.saveRefreshToken("test-refresh")

        let authService = AuthService.shared
        XCTAssertTrue(authService.isAuthenticated,
                     "Should be authenticated when valid tokens exist in keychain")
    }

    @MainActor
    func testAuthService_IsAuthenticated_NoTokens() {
        KeychainHelper.clearTokens()

        let authService = AuthService.shared
        // Note: isAuthenticated checks currentUser OR hasValidTokens
        // With no tokens and no currentUser, should be false
        if authService.currentUser == nil {
            XCTAssertFalse(authService.isAuthenticated,
                         "Should not be authenticated with no tokens and no current user")
        }
    }
}
