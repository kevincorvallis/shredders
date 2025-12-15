import Foundation
import SwiftUI

@MainActor
@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var error: String?

    private let baseURL = "https://shredders-bay.vercel.app/api"

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""

        // Add placeholder assistant message
        let assistantMessage = ChatMessage(role: .assistant, content: "")
        messages.append(assistantMessage)

        isLoading = true
        error = nil

        do {
            // Build API messages
            let apiMessages = messages.dropLast().map { message in
                ChatRequest.APIMessage(
                    role: message.role.rawValue,
                    content: message.content
                )
            }

            // Create request
            guard let url = URL(string: "\(baseURL)/chat") else {
                throw ChatError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ChatRequest(messages: apiMessages)
            request.httpBody = try JSONEncoder().encode(body)

            // Send request and handle streaming response
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ChatError.serverError
            }

            // Process streaming response
            var responseText = ""
            for try await line in bytes.lines {
                // Parse SSE format
                if line.hasPrefix("0:") {
                    // Text chunk
                    let jsonStr = String(line.dropFirst(2))
                    if let data = jsonStr.data(using: .utf8),
                       let text = try? JSONDecoder().decode(String.self, from: data) {
                        responseText += text
                        updateLastMessage(responseText)
                    }
                }
            }

            // Final update
            if responseText.isEmpty {
                responseText = "I couldn't generate a response. Please try again."
            }
            updateLastMessage(responseText)

        } catch {
            self.error = error.localizedDescription
            // Remove the empty assistant message
            if let lastIndex = messages.indices.last,
               messages[lastIndex].role == .assistant && messages[lastIndex].content.isEmpty {
                messages.removeLast()
            }
        }

        isLoading = false
    }

    private func updateLastMessage(_ content: String) {
        guard let lastIndex = messages.indices.last else { return }
        messages[lastIndex].content = content
    }

    func clearMessages() {
        messages.removeAll()
        error = nil
    }
}

enum ChatError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .serverError:
            return "Server error"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
