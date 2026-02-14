import XCTest
@testable import PowderTracker

/// Tests for ChatViewModel - AI chat feature
@MainActor
final class ChatViewModelTests: XCTestCase {

    private var viewModel: ChatViewModel!

    override func setUp() async throws {
        viewModel = ChatViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - Initial State

    func testInitialState_EmptyMessages() {
        XCTAssertTrue(viewModel.messages.isEmpty,
                     "Should start with no messages")
    }

    func testInitialState_EmptyInputText() {
        XCTAssertTrue(viewModel.inputText.isEmpty,
                     "Input text should start empty")
    }

    func testInitialState_NotLoading() {
        XCTAssertFalse(viewModel.isLoading,
                      "Should not be loading initially")
    }

    func testInitialState_NoError() {
        XCTAssertNil(viewModel.error,
                    "Should have no error initially")
    }

    // MARK: - Clear Messages

    func testClearMessages_RemovesAllMessages() {
        // Add some messages manually
        let msg1 = ChatMessage(role: .user, content: "Hello")
        let msg2 = ChatMessage(role: .assistant, content: "Hi there!")
        viewModel.messages = [msg1, msg2]

        viewModel.clearMessages()

        XCTAssertTrue(viewModel.messages.isEmpty,
                     "Should clear all messages")
    }

    func testClearMessages_ClearsError() {
        viewModel.error = "Some error"

        viewModel.clearMessages()

        XCTAssertNil(viewModel.error, "Should clear error state")
    }

    func testClearMessages_OnEmptyList() {
        // Should not crash when clearing empty list
        viewModel.clearMessages()

        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Send Message (Input Validation)

    func testSendMessage_EmptyInput_DoesNothing() async {
        viewModel.inputText = ""

        await viewModel.sendMessage()

        XCTAssertTrue(viewModel.messages.isEmpty,
                     "Should not add message for empty input")
    }

    func testSendMessage_WhitespaceOnly_DoesNothing() async {
        viewModel.inputText = "   \n\t  "

        await viewModel.sendMessage()

        XCTAssertTrue(viewModel.messages.isEmpty,
                     "Should not add message for whitespace-only input")
    }

    func testSendMessage_AddsUserMessage() async {
        viewModel.inputText = "What's the snow like?"

        // This will fail at the network level but should still add the user message
        await viewModel.sendMessage()

        // At minimum, the user message should be added
        let userMessages = viewModel.messages.filter { $0.role == .user }
        XCTAssertEqual(userMessages.count, 1, "Should add one user message")
        XCTAssertEqual(userMessages.first?.content, "What's the snow like?")
    }

    func testSendMessage_ClearsInputText() async {
        viewModel.inputText = "Test message"

        await viewModel.sendMessage()

        XCTAssertTrue(viewModel.inputText.isEmpty,
                     "Input text should be cleared after sending")
    }

    func testSendMessage_SetsLoadingState() async {
        viewModel.inputText = "Test"

        // After sendMessage completes, isLoading should be false
        await viewModel.sendMessage()

        XCTAssertFalse(viewModel.isLoading,
                      "Should not be loading after send completes")
    }

    // MARK: - ChatMessage Model

    func testChatMessage_UserRole() {
        let message = ChatMessage(role: .user, content: "Hello")

        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hello")
        XCTAssertNotNil(message.id) // Identifiable
    }

    func testChatMessage_AssistantRole() {
        let message = ChatMessage(role: .assistant, content: "Response")

        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Response")
    }

    func testChatMessage_Equatable() {
        let msg1 = ChatMessage(role: .user, content: "Hello")
        let msg2 = msg1 // Same instance via value copy

        XCTAssertEqual(msg1, msg2, "Same messages should be equal")
    }

    func testChatMessage_ContentIsMutable() {
        var message = ChatMessage(role: .assistant, content: "")
        message.content = "Updated content"

        XCTAssertEqual(message.content, "Updated content")
    }

    // MARK: - ChatError

    func testChatError_InvalidURL_Description() {
        let error = ChatError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid URL")
    }

    func testChatError_ServerError_Description() {
        let error = ChatError.serverError
        XCTAssertEqual(error.errorDescription, "Server error")
    }

    func testChatError_DecodingError_Description() {
        let error = ChatError.decodingError
        XCTAssertEqual(error.errorDescription, "Failed to decode response")
    }

    func testChatError_AllCasesHaveDescriptions() {
        let errors: [ChatError] = [.invalidURL, .serverError, .decodingError]

        for error in errors {
            XCTAssertNotNil(error.errorDescription,
                          "ChatError.\(error) should have a description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true,
                          "ChatError.\(error) description should not be empty")
        }
    }

    // MARK: - ChatRequest Model

    func testChatRequest_Encoding() throws {
        let request = ChatRequest(messages: [
            ChatRequest.APIMessage(role: "user", content: "Hello"),
            ChatRequest.APIMessage(role: "assistant", content: "Hi!")
        ])

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        let messages = json?["messages"] as? [[String: String]]
        XCTAssertEqual(messages?.count, 2)
        XCTAssertEqual(messages?.first?["role"], "user")
        XCTAssertEqual(messages?.first?["content"], "Hello")
    }

    // MARK: - Role Raw Values

    func testChatMessageRole_RawValues() {
        XCTAssertEqual(ChatMessage.Role.user.rawValue, "user")
        XCTAssertEqual(ChatMessage.Role.assistant.rawValue, "assistant")
    }
}
