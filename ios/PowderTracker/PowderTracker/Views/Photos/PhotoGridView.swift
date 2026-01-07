import SwiftUI

struct PhotoGridView: View {
    let mountainId: String
    let webcamId: String?

    @State private var photos: [Photo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else if photos.isEmpty {
                emptyView
            } else {
                photosGrid
            }
        }
        .task {
            await loadPhotos()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading photos...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                Task {
                    await loadPhotos()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No photos yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Be the first to upload a photo!")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var photosGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { photo in
                    PhotoCardView(photo: photo) {
                        await loadPhotos()
                    }
                }
            }
            .padding()
        }
    }

    private func loadPhotos() async {
        isLoading = true
        errorMessage = nil

        do {
            photos = try await PhotoService.shared.fetchPhotos(
                for: mountainId,
                webcamId: webcamId
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    PhotoGridView(mountainId: "baker", webcamId: nil)
}
