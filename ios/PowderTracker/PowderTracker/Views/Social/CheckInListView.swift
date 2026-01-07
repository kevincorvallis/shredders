import SwiftUI

struct CheckInListView: View {
    let mountainId: String
    let limit: Int
    let showForm: Bool

    @Environment(AuthService.self) private var authService
    @State private var checkIns: [CheckIn] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCheckInForm = false

    init(mountainId: String, limit: Int = 20, showForm: Bool = true) {
        self.mountainId = mountainId
        self.limit = limit
        self.showForm = showForm
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recent Check-ins")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if showForm, authService.isAuthenticated, !showingCheckInForm {
                    Button {
                        showingCheckInForm = true
                    } label: {
                        Label("Check In", systemImage: "plus")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()

            Divider()

            // Content
            Group {
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(message: errorMessage)
                } else if checkIns.isEmpty {
                    emptyView
                } else {
                    checkInsListView
                }
            }
        }
        .task {
            await loadCheckIns()
        }
        .sheet(isPresented: $showingCheckInForm) {
            CheckInFormView(mountainId: mountainId) { newCheckIn in
                checkIns.insert(newCheckIn, at: 0)
            }
            .environment(authService)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading check-ins...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await loadCheckIns() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No check-ins yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Be the first to check in at this mountain!")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            if showForm, authService.isAuthenticated {
                Button {
                    showingCheckInForm = true
                } label: {
                    Text("Check In Now")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var checkInsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(checkIns) { checkIn in
                    CheckInCardView(checkIn: checkIn) {
                        // Remove from local list when deleted
                        checkIns.removeAll { $0.id == checkIn.id }
                    }
                }
            }
            .padding()
        }
    }

    private func loadCheckIns() async {
        isLoading = true
        errorMessage = nil

        do {
            checkIns = try await CheckInService.shared.fetchCheckIns(
                for: mountainId,
                limit: limit
            )
        } catch {
            errorMessage = "Failed to load check-ins: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

#Preview {
    CheckInListView(mountainId: "baker")
        .environment(AuthService.shared)
}
