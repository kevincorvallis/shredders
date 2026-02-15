import SwiftUI
import Nuke
import NukeUI

struct WebcamsView: View {
    var mountainId: String? = nil  // Optional parameter from parent
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"
    @State private var webcams: [WebcamData] = []
    @State private var roadWebcams: [RoadWebcamData] = []
    @State private var mountainName: String = ""
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedWebcam: WebcamData?
    @State private var refreshID = UUID()

    // Use passed mountainId if available, otherwise fall back to AppStorage
    private var effectiveMountainId: String {
        mountainId ?? selectedMountainId
    }

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
                    } else if webcams.isEmpty && roadWebcams.isEmpty {
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
                        // Resort Webcams Section
                        if !webcams.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "video")
                                        .font(.headline)
                                    Text("Resort Webcams")
                                        .font(.headline)
                                }
                                .padding(.horizontal)
                                .foregroundColor(.primary)

                                ForEach(webcams) { webcam in
                                    WebcamCard(webcam: webcam, refreshID: refreshID) {
                                        selectedWebcam = webcam
                                    }
                                }
                            }
                        }

                        // Road Webcams Section
                        if !roadWebcams.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "road.lanes")
                                        .font(.headline)
                                    Text("Road & Highway Webcams")
                                        .font(.headline)
                                }
                                .padding(.horizontal)
                                .padding(.top, webcams.isEmpty ? 0 : 8)
                                .foregroundColor(.primary)

                                ForEach(roadWebcams) { roadWebcam in
                                    RoadWebcamCard(webcam: roadWebcam, refreshID: refreshID) {
                                        // Convert to WebcamData for full screen view
                                        selectedWebcam = WebcamData(
                                            id: roadWebcam.id,
                                            name: roadWebcam.name,
                                            url: roadWebcam.url
                                        )
                                    }
                                }
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
                    RefreshButton(isLoading: isLoading) {
                        Task { await loadWebcams() }
                    }
                }
            }
            .refreshable {
                refreshID = UUID()
            }
            .task(id: effectiveMountainId) {
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
            guard let url = URL(string: "\(AppConfig.apiBaseURL)/mountains/\(effectiveMountainId)") else {
                self.error = "Unable to load webcams. Please try again."
                isLoading = false
                return
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MountainDetail.self, from: data)

            mountainName = response.shortName
            webcams = response.webcams.map { webcam in
                WebcamData(id: webcam.id, name: webcam.name, url: webcam.url)
            }
            roadWebcams = response.roadWebcams?.map { roadWebcam in
                RoadWebcamData(
                    id: roadWebcam.id,
                    name: roadWebcam.name,
                    url: roadWebcam.url,
                    highway: roadWebcam.highway,
                    milepost: roadWebcam.milepost,
                    agency: roadWebcam.agency
                )
            } ?? []
        } catch {
            self.error = "Unable to load webcams. Please check your connection."
        }

        isLoading = false
    }
}

struct WebcamData: Identifiable {
    let id: String
    let name: String
    let url: String
}

struct RoadWebcamData: Identifiable {
    let id: String
    let name: String
    let url: String
    let highway: String
    let milepost: String?
    let agency: String
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

            LazyImage(url: URL(string: webcam.url)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(.cornerRadiusButton)
                } else if state.error != nil {
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
                } else {
                    ZStack {
                        Color(.secondarySystemBackground)
                        ProgressView()
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                }
            }
            .processors([ImageProcessors.Resize(width: 800)])
            .priority(.high)
            .id(refreshID)

            Text("Tap to view fullscreen")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .onTapGesture(perform: onTap)
    }
}

struct RoadWebcamCard: View {
    let webcam: RoadWebcamData
    let refreshID: UUID
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(webcam.name)
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text(webcam.highway)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        if let milepost = webcam.milepost {
                            Text("• MP \(milepost)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("• \(webcam.agency)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyImage(url: URL(string: webcam.url)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(.cornerRadiusButton)
                } else if state.error != nil {
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
                } else {
                    ZStack {
                        Color(.secondarySystemBackground)
                        ProgressView()
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                }
            }
            .processors([ImageProcessors.Resize(width: 800)])
            .priority(.high)
            .id(refreshID)

            Text("Tap to view fullscreen")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
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

                LazyImage(url: URL(string: webcam.url)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if state.error != nil {
                        VStack(spacing: 12) {
                            Image(systemName: "video.slash")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Unable to load webcam")
                                .foregroundColor(.gray)
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                }
                .priority(.high)
                    .id(currentRefreshID)

                Spacer()
            }
        }
    }
}

// MARK: - Error Card

private struct ErrorCard: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Failed to load data")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
    }
}

#Preview {
    WebcamsView()
}
