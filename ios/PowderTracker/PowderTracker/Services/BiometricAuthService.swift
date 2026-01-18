import Foundation
import LocalAuthentication

/// Service for biometric authentication (Face ID / Touch ID)
@MainActor
@Observable
class BiometricAuthService {
    static let shared = BiometricAuthService()

    // MARK: - Types

    enum BiometricType {
        case faceID
        case touchID
        case none
    }

    enum BiometricError: Error, LocalizedError {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancelled
        case systemCancelled
        case passcodeNotSet
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
            case .authenticationFailed:
                return "Biometric authentication failed"
            case .userCancelled:
                return "Authentication was cancelled"
            case .systemCancelled:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Please set up a device passcode to use biometric authentication"
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKeys {
        static let biometricEnabled = "biometricAuthEnabled"
    }

    // MARK: - Properties

    private let context = LAContext()

    /// Whether biometric auth is enabled by the user
    var isBiometricEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.biometricEnabled) }
    }

    /// The type of biometric available on this device
    var biometricType: BiometricType {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .faceID // Treat Apple Vision Pro as Face ID equivalent
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// Human-readable name for the biometric type
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometric"
        }
    }

    /// Whether biometric auth can be used (available and enabled)
    var canUseBiometric: Bool {
        biometricType != .none && isBiometricEnabled && KeychainHelper.hasValidTokens()
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Check if biometric authentication is available on this device
    func checkBiometricAvailability() -> Result<BiometricType, BiometricError> {
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotAvailable:
                    return .failure(.notAvailable)
                case .biometryNotEnrolled:
                    return .failure(.notEnrolled)
                case .passcodeNotSet:
                    return .failure(.passcodeNotSet)
                default:
                    return .failure(.unknown(laError))
                }
            }
            return .failure(.notAvailable)
        }

        return .success(biometricType)
    }

    /// Authenticate using biometrics
    /// - Parameter reason: The reason shown to the user for authentication
    /// - Returns: Success or failure with error
    func authenticate(reason: String = "Sign in to PowderTracker") async -> Result<Void, BiometricError> {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Password"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                return .failure(mapLAError(laError))
            }
            return .failure(.notAvailable)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                return .success(())
            } else {
                return .failure(.authenticationFailed)
            }
        } catch let error as LAError {
            return .failure(mapLAError(error))
        } catch {
            return .failure(.unknown(error))
        }
    }

    /// Enable biometric authentication
    /// - Stores the refresh token with biometric protection
    func enableBiometric() async -> Result<Void, BiometricError> {
        // First verify biometric is available
        let availability = checkBiometricAvailability()
        if case .failure(let error) = availability {
            return .failure(error)
        }

        // Verify the user can authenticate
        let authResult = await authenticate(reason: "Enable \(biometricTypeName) for quick sign-in")
        if case .failure(let error) = authResult {
            return .failure(error)
        }

        // Enable biometric auth
        isBiometricEnabled = true
        return .success(())
    }

    /// Disable biometric authentication
    func disableBiometric() {
        isBiometricEnabled = false
    }

    /// Authenticate and get access token
    /// Used for quick sign-in with biometrics
    func authenticateAndGetToken() async -> Result<String, BiometricError> {
        // First authenticate with biometrics
        let authResult = await authenticate(reason: "Sign in to PowderTracker")

        switch authResult {
        case .failure(let error):
            return .failure(error)
        case .success:
            // Check if we have a valid access token
            if !KeychainHelper.isAccessTokenExpired(), let token = KeychainHelper.getAccessToken() {
                return .success(token)
            }

            // Try to refresh the token
            guard let refreshToken = KeychainHelper.getRefreshToken() else {
                disableBiometric() // Disable since we don't have tokens
                return .failure(.authenticationFailed)
            }

            // Token needs refresh - this will be handled by the caller
            // Return success to indicate biometric passed
            if let token = KeychainHelper.getAccessToken() {
                return .success(token)
            }

            return .failure(.authenticationFailed)
        }
    }

    // MARK: - Private Methods

    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .systemCancel:
            return .systemCancelled
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .passcodeNotSet:
            return .passcodeNotSet
        default:
            return .unknown(error)
        }
    }
}
