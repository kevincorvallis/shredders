//
//  EventPhotosView.swift
//  PowderTracker
//
//  Photo gallery view for events with upload and full-screen viewer.
//

import SwiftUI
import PhotosUI

struct EventPhotosView: View {
    let eventId: String
    @State private var viewModel: EventPhotosViewModel
    @State private var showingImagePicker = false
    @State private var photosPickerItem: PhotosPickerItem?

    init(eventId: String) {
        self.eventId = eventId
        self._viewModel = State(initialValue: EventPhotosViewModel(eventId: eventId))
    }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.photos.isEmpty {
                loadingView
            } else if viewModel.isGated {
                gatedView
            } else {
                // Upload bar (if not uploading)
                if !viewModel.isUploading {
                    uploadBar
                }

                // Upload progress
                if viewModel.isUploading {
                    uploadProgressView
                }

                // Photos grid or empty state
                if viewModel.isEmpty {
                    emptyView
                } else {
                    photosGrid
                }
            }
        }
        .task {
            await viewModel.loadPhotos()
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectedImage = image
                }
            }
        }
        .sheet(isPresented: .init(
            get: { viewModel.selectedImage != nil },
            set: { if !$0 { viewModel.cancelUpload() } }
        )) {
            uploadSheet
        }
        .fullScreenCover(item: $viewModel.selectedPhotoIndex) { index in
            PhotoViewerView(
                photos: viewModel.photos,
                initialIndex: index,
                onDelete: { photo in
                    Task { await viewModel.deletePhoto(photo) }
                }
            )
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: .spacingM) {
            ProgressView()
            Text("Loading photos...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Gated View

    private var gatedView: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: .spacingS) {
                Text("\(viewModel.photoCount) photos")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(viewModel.gatedMessage ?? "RSVP to see photos")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: .spacingS) {
                Text("No photos yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Be the first to share a photo!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Upload Bar

    private var uploadBar: some View {
        PhotosPicker(selection: $photosPickerItem, matching: .images) {
            HStack(spacing: .spacingS) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add Photo")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacingM)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(.cornerRadiusButton)
        }
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
        .accessibilityLabel("Add photo")
        .accessibilityHint("Double tap to select a photo from your library")
    }

    // MARK: - Upload Progress

    private var uploadProgressView: some View {
        HStack(spacing: .spacingM) {
            ProgressView()

            if case .uploading(let progress) = viewModel.uploadState {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uploading...")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                }
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusButton)
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
    }

    // MARK: - Photos Grid

    private var photosGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(viewModel.photos.enumerated()), id: \.element.id) { index, photo in
                    PhotoThumbnailView(photo: photo)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .onTapGesture {
                            viewModel.selectedPhotoIndex = index
                            HapticFeedback.light.trigger()
                        }
                        .task {
                            await viewModel.loadMoreIfNeeded(currentItem: photo)
                        }
                        .accessibilityLabel(photoAccessibilityLabel(for: photo))
                        .accessibilityHint("Double tap to view full screen")
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Accessibility Helpers

    private func photoAccessibilityLabel(for photo: EventPhoto) -> String {
        var label = "Photo"
        if let caption = photo.caption {
            label += ": \(caption)"
        }
        if let user = photo.user {
            label += ", by \(user.displayNameOrUsername)"
        }
        label += ", \(photo.relativeTime)"
        return label
    }

    // MARK: - Upload Sheet

    private var uploadSheet: some View {
        NavigationStack {
            VStack(spacing: .spacingL) {
                // Preview
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(.cornerRadiusCard)
                }

                // Caption input
                TextField("Add a caption (optional)", text: $viewModel.uploadCaption)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Spacer()

                // Upload button
                Button {
                    Task {
                        await viewModel.uploadPhoto()
                    }
                } label: {
                    HStack {
                        if viewModel.isUploading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                        }
                        Text(viewModel.isUploading ? "Uploading..." : "Upload Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canUpload ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(.cornerRadiusButton)
                }
                .disabled(!viewModel.canUpload)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Share Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelUpload()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Photo Thumbnail View

struct PhotoThumbnailView: View {
    let photo: EventPhoto

    var body: some View {
        AsyncImage(url: URL(string: photo.displayUrl)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            case .empty:
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(ProgressView())
            @unknown default:
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
            }
        }
    }
}

// MARK: - Full Screen Photo Viewer

struct PhotoViewerView: View {
    let photos: [EventPhoto]
    let initialIndex: Int
    let onDelete: (EventPhoto) -> Void

    @State private var currentIndex: Int
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    init(photos: [EventPhoto], initialIndex: Int, onDelete: @escaping (EventPhoto) -> Void) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.onDelete = onDelete
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    VStack {
                        AsyncImage(url: URL(string: photo.url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            case .failure:
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                    Text("Failed to load")
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }

                        // Caption and info
                        if let caption = photo.caption {
                            Text(caption)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding()
                        }

                        if let user = photo.user {
                            HStack {
                                Text("by \(user.displayNameOrUsername)")
                                    .font(.caption)
                                Text("•")
                                Text(photo.relativeTime)
                                    .font(.caption)
                            }
                            .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                    .accessibilityLabel("Close photo viewer")
                }
                Spacer()

                // Delete button
                HStack {
                    Spacer()
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red.opacity(0.8))
                            .padding()
                    }
                    .accessibilityLabel("Delete photo")
                    .accessibilityHint("Double tap to delete this photo")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Photo viewer, \(currentIndex + 1) of \(photos.count)")
        .confirmationDialog(
            "Delete Photo",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                let photo = photos[currentIndex]
                onDelete(photo)
                if photos.count <= 1 {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this photo?")
        }
    }
}

// MARK: - Identifiable Extension for Int

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventPhotosView(eventId: "preview-event-id")
            .navigationTitle("Photos")
    }
}
