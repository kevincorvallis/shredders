//
//  ToastView.swift
//  PowderTracker
//
//  Toast/banner component for user feedback
//

import SwiftUI

/// Toast message type for styling
enum ToastType {
    case success
    case error
    case info
    case warning

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }

    var backgroundColor: Color {
        switch self {
        case .success: return .green.opacity(0.15)
        case .error: return .red.opacity(0.15)
        case .info: return .blue.opacity(0.15)
        case .warning: return .orange.opacity(0.15)
        }
    }
}

/// Toast message model
struct ToastMessage: Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String?

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

/// Toast view for displaying feedback messages
struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(toast.type.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let message = toast.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(toast.type.backgroundColor)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

/// View modifier for showing toasts
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    let duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if let toast = toast {
                    ToastView(toast: toast) {
                        withAnimation(.spring()) {
                            self.toast = nil
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .onAppear {
                        scheduleAutoDismiss()
                    }
                }

                Spacer()
            }
        }
        .animation(.spring(), value: toast)
    }

    private func scheduleAutoDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.spring()) {
                toast = nil
            }
        }
    }
}

extension View {
    /// Shows a toast message overlay
    /// - Parameters:
    ///   - toast: Binding to the optional toast message
    ///   - duration: How long to show the toast (default 3 seconds)
    func toast(_ toast: Binding<ToastMessage?>, duration: TimeInterval = 3.0) -> some View {
        modifier(ToastModifier(toast: toast, duration: duration))
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 20) {
        ToastView(toast: ToastMessage(type: .success, title: "Success!", message: "You've joined the event")) {}
        ToastView(toast: ToastMessage(type: .error, title: "Error", message: "Failed to join event. Please try again.")) {}
        ToastView(toast: ToastMessage(type: .info, title: "Info", message: "Pull to refresh for latest events")) {}
        ToastView(toast: ToastMessage(type: .warning, title: "Warning", message: "Event is starting soon!")) {}
    }
    .padding()
}
