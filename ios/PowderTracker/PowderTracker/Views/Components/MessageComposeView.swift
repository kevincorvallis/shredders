import SwiftUI
import MessageUI

/// A SwiftUI wrapper for MFMessageComposeViewController to send messages via iMessage/SMS
struct MessageComposeView: UIViewControllerRepresentable {
    let messageBody: String
    var recipients: [String] = []
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = messageBody
        controller.recipients = recipients.isEmpty ? nil : recipients
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    @MainActor
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onDismiss: (() -> Void)?

        init(onDismiss: (() -> Void)?) {
            self.onDismiss = onDismiss
        }

        nonisolated func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            Task { @MainActor in
                controller.dismiss(animated: true) { [weak self] in
                    self?.onDismiss?()
                }
            }
        }
    }
}

/// Check if the device can send messages
extension MessageComposeView {
    static var canSendMessages: Bool {
        MFMessageComposeViewController.canSendText()
    }
}

/// View modifier to present message compose sheet
struct MessageComposeModifier: ViewModifier {
    @Binding var isPresented: Bool
    let messageBody: String
    var recipients: [String] = []

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                if MessageComposeView.canSendMessages {
                    MessageComposeView(
                        messageBody: messageBody,
                        recipients: recipients,
                        onDismiss: {
                            isPresented = false
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    MessageUnavailableView {
                        isPresented = false
                    }
                }
            }
    }
}

/// Fallback view when messaging is not available (e.g., on iPad without Messages)
private struct MessageUnavailableView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Messages Unavailable")
                .font(.headline)

            Text("This device cannot send messages. Try copying the link instead.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("OK") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

extension View {
    /// Present a message compose sheet
    func messageComposeSheet(
        isPresented: Binding<Bool>,
        body: String,
        recipients: [String] = []
    ) -> some View {
        modifier(MessageComposeModifier(
            isPresented: isPresented,
            messageBody: body,
            recipients: recipients
        ))
    }
}
