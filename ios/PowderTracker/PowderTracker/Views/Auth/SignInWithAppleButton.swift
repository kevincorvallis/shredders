import SwiftUI
import AuthenticationServices
import CryptoKit

struct SignInWithAppleButton: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var currentNonce: String?
    @State private var errorMessage: String?
    @State private var isCheckingAvailability = true
    @State private var isAvailable = true

    // Detect if running on simulator
    #if targetEnvironment(simulator)
    private var isSimulator: Bool { true }
    #else
    private var isSimulator: Bool { false }
    #endif

    var body: some View {
        VStack(spacing: 8) {
            if isCheckingAvailability {
                ProgressView()
                    .frame(height: 50)
            } else if !isAvailable {
                VStack(spacing: 8) {
                    Button {
                        // Fallback message
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Sign in with Apple Unavailable")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 4)
                    }
                    .disabled(true)

                    Text("Please sign in to iCloud in Settings → [Your Name] to use Sign in with Apple")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
            } else {
                SignInWithAppleButtonView(
                    onRequest: { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        Task {
                            await handleSignInWithApple(result: result)
                        }
                    }
                )
                .frame(height: 50)
                .cornerRadius(10)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
            }
        }
        .task {
            await checkSignInWithAppleAvailability()
        }
    }

    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Failed to get credentials from Apple"
                return
            }

            do {
                try await authService.signInWithApple(idToken: idTokenString, nonce: nonce)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    // User cancelled, don't show error
                    break
                case .unknown:
                    // Check for specific underlying error details
                    let nsError = error as NSError
                    if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                        print("Underlying error: \(underlyingError)")
                    }

                    // Provide more helpful error message
                    if isSimulator {
                        errorMessage = "Sign in with Apple doesn't work reliably on simulator. Please use email/password or test on a physical device."
                    } else {
                        errorMessage = "Unable to sign in with Apple. This usually means:\n• You're not signed into iCloud (Settings → [Your Name])\n• Network connectivity issues\n\nPlease try email/password instead."
                    }
                case .notHandled:
                    errorMessage = "Sign in with Apple is not configured. Please use email/password."
                case .invalidResponse:
                    errorMessage = "Received invalid response from Apple. Please try again or use email/password."
                case .notInteractive:
                    errorMessage = "Sign in requires user interaction. Please try again."
                case .failed:
                    errorMessage = "Sign in with Apple failed. Please check your internet connection and try again."
                case .matchedExcludedCredential, .credentialImport, .credentialExport,
                     .preferSignInWithApple, .deviceNotConfiguredForPasskeyCreation:
                    // Handle newer error cases
                    errorMessage = "Sign in with Apple is not available. Please use email/password instead."
                @unknown default:
                    errorMessage = "An unexpected error occurred. Please use email/password instead.\nError: \(authError.localizedDescription)"
                }
            } else {
                errorMessage = "Sign in with Apple failed: \(error.localizedDescription)\n\nPlease use email/password instead."
            }
        }
    }

    // MARK: - Nonce Generation

    private func randomNonceString(length: Int = 32) -> String {
        guard length > 0 else {
            // Return a default nonce if invalid length provided
            return randomNonceString(length: 32)
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    // If secure random fails, fall back to arc4random (less secure but won't crash)
                    #if DEBUG
                    print("Warning: SecRandomCopyBytes failed with OSStatus \(errorCode), using fallback")
                    #endif
                    return UInt8(arc4random_uniform(256))
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    // MARK: - Availability Check

    private func checkSignInWithAppleAvailability() async {
        // Sign in with Apple is available on all iOS 13+ devices
        // Rather than pre-emptively checking (which can give false negatives),
        // we assume it's available and let the user try.
        // If it fails due to iCloud not being signed in, the error handler
        // in handleSignInWithApple will show a helpful message.
        isCheckingAvailability = false
        isAvailable = true
    }
}

// UIKit wrapper for ASAuthorizationAppleIDButton
struct SignInWithAppleButtonView: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTapButton), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }

    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void

        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
             onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }

        @objc func didTapButton() {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            onRequest(request)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return UIWindow()
            }
            return window
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }
    }
}
