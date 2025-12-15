import SwiftUI

struct WebcamsView: View {
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"
    @State private var webcams: [WebcamData] = []
    @State private var mountainName: String = ""
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedWebcam: WebcamData?
    @State private var refreshID = UUID()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading webcams...")
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else if let error = error {
                        ErrorCard(message: error) {
                            Task { await loadWebcams() }
                        }
                    } else if webcams.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "video.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No webcams available")
                                .font(.headline)
                            Text("This mountain doesn't have any webcams configured.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        ForEach(webcams) { webcam in
                            WebcamCard(webcam: webcam, refreshID: refreshID) {
                                selectedWebcam = webcam
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(mountainName.isEmpty ? "Webcams" : "\(mountainName) Webcams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        refreshID = UUID()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                refreshID = UUID()
            }
            .task(id: selectedMountainId) {
                await loadWebcams()
            }
            .fullScreenCover(item: $selectedWebcam) { webcam in
                WebcamFullScreen(webcam: webcam, refreshID: refreshID) {
                    selectedWebcam = nil
                }
            }
        }
    }

    private func loadWebcams() async {
        isLoading = true
        error = nil

        do {
            let url = URL(string: "https://shredders-bay.vercel.app/api/mountains/\(selectedMountainId)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MountainDetail.self, from: data)

            mountainName = response.shortName
            webcams = response.webcams.map { webcam in
                WebcamData(id: webcam.id, name: webcam.name, url: webcam.url)
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct WebcamData: Identifiable {
    let id: String
    let name: String
    let url: String
}

struct WebcamCard: View {
    let webcam: WebcamData
    let refreshID: UUID
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(webcam.name)
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            AsyncImage(url: URL(string: webcam.url)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color(.secondarySystemBackground)
                        ProgressView()
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                case .failure(_):
                    ZStack {
                        Color(.secondarySystemBackground)
                        VStack(spacing: 8) {
                            Image(systemName: "video.slash")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("Unable to load webcam")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                @unknown default:
                    EmptyView()
                }
            }
            .id(refreshID)

            Text("Tap to view fullscreen")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .onTapGesture(perform: onTap)
    }
}

struct WebcamFullScreen: View {
    let webcam: WebcamData
    let refreshID: UUID
    let onDismiss: () -> Void

    @State private var currentRefreshID: UUID

    init(webcam: WebcamData, refreshID: UUID, onDismiss: @escaping () -> Void) {
        self.webcam = webcam
        self.refreshID = refreshID
        self.onDismiss = onDismiss
        self._currentRefreshID = State(initialValue: refreshID)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Text(webcam.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        currentRefreshID = UUID()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()

                Spacer()

                AsyncImage(url: URL(string: webcam.url)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure(_):
                        VStack(spacing: 12) {
                            Image(systemName: "video.slash")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Unable to load webcam")
                                .foregroundColor(.gray)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .id(currentRefreshID)

                Spacer()
            }
        }
    }
}

#Preview {
    WebcamsView()
}
