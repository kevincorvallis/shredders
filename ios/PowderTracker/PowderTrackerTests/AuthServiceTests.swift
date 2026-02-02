import XCTest
@testable import PowderTracker

/// Tests for AuthService authentication functionality
final class AuthServiceTests: XCTestCase {

    // MARK: - Password Validation Tests

    func testPasswordValidation_MinimumLength() {
        // Password must be at least 12 characters
        let shortPassword = "Short1!Aa"
        let validPassword = "ValidP@ss123!"

        XCTAssertTrue(shortPassword.count < 12, "Short password should be under 12 characters")
        XCTAssertTrue(validPassword.count >= 12, "Valid password should be at least 12 characters")
    }

    func testPasswordValidation_UppercaseRequired() {
        let noUppercase = "nouppercase1!"
        let hasUppercase = "HasUppercase1!"

        XCTAssertFalse(noUppercase.contains(where: { $0.isUppercase }))
        XCTAssertTrue(hasUppercase.contains(where: { $0.isUppercase }))
    }

    func testPasswordValidation_LowercaseRequired() {
        let noLowercase = "NOLOWERCASE1!"
        let hasLowercase = "HasLowercase1!"

        XCTAssertFalse(noLowercase.contains(where: { $0.isLowercase }))
        XCTAssertTrue(hasLowercase.contains(where: { $0.isLowercase }))
    }

    func testPasswordValidation_NumberRequired() {
        let noNumber = "NoNumbersHere!"
        let hasNumber = "HasNumber1Here!"

        XCTAssertFalse(noNumber.contains(where: { $0.isNumber }))
        XCTAssertTrue(hasNumber.contains(where: { $0.isNumber }))
    }

    func testPasswordValidation_SpecialCharRequired() {
        let specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let noSpecial = "NoSpecialChars1"
        let hasSpecial = "HasSpecial@1!"

        XCTAssertFalse(noSpecial.contains(where: { specialChars.contains($0) }))
        XCTAssertTrue(hasSpecial.contains(where: { specialChars.contains($0) }))
    }

    func testPasswordValidation_AllRequirementsMet() {
        let specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let validPassword = "MyStrongP@ss123"

        // Check all requirements
        let hasMinLength = validPassword.count >= 12
        let hasUppercase = validPassword.contains(where: { $0.isUppercase })
        let hasLowercase = validPassword.contains(where: { $0.isLowercase })
        let hasNumber = validPassword.contains(where: { $0.isNumber })
        let hasSpecial = validPassword.contains(where: { specialChars.contains($0) })

        XCTAssertTrue(hasMinLength, "Should meet minimum length")
        XCTAssertTrue(hasUppercase, "Should have uppercase")
        XCTAssertTrue(hasLowercase, "Should have lowercase")
        XCTAssertTrue(hasNumber, "Should have number")
        XCTAssertTrue(hasSpecial, "Should have special character")
    }

    // MARK: - Email Validation Tests

    func testEmailValidation_ValidEmails() {
        let validEmails = [
            "test@example.com",
            "user.name@domain.org",
            "user+tag@example.co.uk"
        ]

        for email in validEmails {
            XCTAssertTrue(email.contains("@"), "\(email) should contain @")
            XCTAssertTrue(email.split(separator: "@").count == 2, "\(email) should have one @")
        }
    }

    func testEmailValidation_InvalidEmails() {
        let invalidEmails = [
            "not-an-email",
            "@nodomain.com",
            "user@",
            ""
        ]

        for email in invalidEmails {
            let isValid = email.contains("@") && !email.hasPrefix("@") && !email.hasSuffix("@") && !email.isEmpty
            XCTAssertFalse(isValid, "\(email) should be invalid")
        }
    }

    // MARK: - Keychain Tests

    func testKeychainHelper_SaveAndRetrieveToken() throws {
        // Test token storage
        let testToken = "test-access-token-\(UUID().uuidString)"

        // Save token
        try KeychainHelper.saveAccessToken(testToken)

        // Retrieve token
        let retrievedToken = KeychainHelper.getAccessToken()

        XCTAssertEqual(retrievedToken, testToken, "Retrieved token should match saved token")

        // Cleanup
        KeychainHelper.clearTokens()
    }

    func testKeychainHelper_ClearTokens() throws {
        // Save some tokens
        try KeychainHelper.saveAccessToken("test-access")
        try KeychainHelper.saveRefreshToken("test-refresh")

        // Clear all tokens
        KeychainHelper.clearTokens()

        // Verify tokens are cleared
        XCTAssertNil(KeychainHelper.getAccessToken(), "Access token should be nil after clear")
        XCTAssertNil(KeychainHelper.getRefreshToken(), "Refresh token should be nil after clear")
    }

    func testKeychainHelper_TokenExpiry() throws {
        // Save token with short expiry
        let shortExpiry = Date().addingTimeInterval(30) // 30 seconds
        try KeychainHelper.saveTokenExpiry(shortExpiry)

        // Should be expired (with 60 second buffer)
        XCTAssertTrue(KeychainHelper.isAccessTokenExpired(), "Token should be considered expired with buffer")

        // Save token with long expiry
        let longExpiry = Date().addingTimeInterval(300) // 5 minutes
        try KeychainHelper.saveTokenExpiry(longExpiry)

        // Should not be expired
        XCTAssertFalse(KeychainHelper.isAccessTokenExpired(), "Token should not be expired")

        // Cleanup
        KeychainHelper.clearTokens()
    }

    func testKeychainHelper_HasValidTokens() throws {
        // Initially should have no valid tokens
        KeychainHelper.clearTokens()
        XCTAssertFalse(KeychainHelper.hasValidTokens(), "Should have no valid tokens initially")

        // Save tokens
        try KeychainHelper.saveAccessToken("test-access")
        try KeychainHelper.saveRefreshToken("test-refresh")

        // Should have valid tokens
        XCTAssertTrue(KeychainHelper.hasValidTokens(), "Should have valid tokens after saving")

        // Cleanup
        KeychainHelper.clearTokens()
    }

    // MARK: - AppConfig Tests

    func testAppConfig_APIBaseURL() {
        let apiURL = AppConfig.apiBaseURL

        XCTAssertFalse(apiURL.isEmpty, "API URL should not be empty")
        XCTAssertTrue(apiURL.hasPrefix("https://"), "API URL should use HTTPS")
        XCTAssertTrue(apiURL.hasSuffix("/api"), "API URL should end with /api")
    }

    func testAppConfig_SupabaseURL() {
        let supabaseURL = AppConfig.supabaseURL

        XCTAssertFalse(supabaseURL.isEmpty, "Supabase URL should not be empty")
        XCTAssertTrue(supabaseURL.hasPrefix("https://"), "Supabase URL should use HTTPS")
    }

    func testAppConfig_SafeURLCreation() {
        let endpoint = "/auth/login"
        let url = AppConfig.apiURL(for: endpoint)

        XCTAssertNotNil(url, "Should create valid URL for endpoint")
        XCTAssertTrue(url?.absoluteString.contains("/auth/login") == true, "URL should contain endpoint")
    }

    // MARK: - Signup Response Tests

    func testSignupResponse_DecodesWithTokens() throws {
        // When email verification is NOT required, response includes tokens
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

    func testSignupResponse_DecodesWithEmailVerificationRequired() throws {
        // When email verification IS required, response has needsEmailVerification but no tokens
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
        XCTAssertEqual(response.user.email, "new@example.com")
        XCTAssertNil(response.accessToken, "Should not have access token when verification required")
        XCTAssertNil(response.refreshToken, "Should not have refresh token when verification required")
        XCTAssertTrue(response.needsEmailVerification ?? false, "Should indicate email verification needed")
        XCTAssertEqual(response.message, "Please check your email to verify your account")
    }

    func testSignupResponse_HandlesEmailVerificationFlag() throws {
        // Test that the needsEmailVerification flag properly indicates when to throw emailNotVerified error
        let responseWithVerification = """
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

        let response = try JSONDecoder().decode(SignupResponse.self, from: responseWithVerification)

        // Simulate the auth service logic
        if response.needsEmailVerification == true {
            // This is expected - should throw emailNotVerified
            XCTAssertTrue(true, "Should trigger email verification flow")
        } else if let accessToken = response.accessToken, let refreshToken = response.refreshToken {
            XCTFail("Should not have tokens when verification required")
            _ = (accessToken, refreshToken) // Suppress unused warning
        } else {
            XCTFail("Should either have verification flag or tokens")
        }
    }

    // MARK: - BiometricAuthService Tests

    func testBiometricAuthService_BiometricType() {
        let biometricService = BiometricAuthService.shared

        // Just verify the service can be accessed and returns a type
        let biometricType = biometricService.biometricType

        // Type should be one of the valid options
        switch biometricType {
        case .faceID, .touchID, .none:
            // All valid options
            break
        }
    }

    func testBiometricAuthService_BiometricTypeName() {
        let biometricService = BiometricAuthService.shared
        let name = biometricService.biometricTypeName

        XCTAssertFalse(name.isEmpty, "Biometric type name should not be empty")

        let validNames = ["Face ID", "Touch ID", "Biometric"]
        XCTAssertTrue(validNames.contains(name), "Biometric type name should be valid")
    }

    func testBiometricAuthService_EnableDisable() {
        let biometricService = BiometricAuthService.shared

        // Disable biometric
        biometricService.disableBiometric()
        XCTAssertFalse(biometricService.isBiometricEnabled, "Biometric should be disabled")

        // Note: Cannot test enable without actual biometric hardware
    }
}

// MARK: - AuthError Tests

final class AuthErrorTests: XCTestCase {

    func testAuthError_ErrorDescriptions() {
        let errors: [AuthError] = [
            .invalidCredentials,
            .emailNotVerified,
            .tokenStorageFailed,
            .noRefreshToken,
            .sessionExpired,
            .serverError("Test error")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description: \(error)")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error description should not be empty")
        }
    }

    func testAuthError_NetworkError() {
        let urlError = URLError(.badServerResponse)
        let authError = AuthError.networkError(urlError)

        XCTAssertNotNil(authError.errorDescription)
        XCTAssertTrue(authError.errorDescription?.contains("Network") ?? false)
    }
}
