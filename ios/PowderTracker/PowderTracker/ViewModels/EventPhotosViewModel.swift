//
//  EventPhotosViewModel.swift
//  PowderTracker
//
//  ViewModel for event photos gallery with upload support.
//

import Foundation
import SwiftUI
import PhotosUI
import UIKit

@MainActor
@Observable
final class EventPhotosViewModel {

    // MARK: - State

    var photos: [EventPhoto] = []
    var photoCount: Int = 0
    var isGated: Bool = true
    var gatedMessage: String?

    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String?
    var hasMore: Bool = false

    // Upload state
    var uploadState: PhotoUploadState = .idle
    var selectedImage: UIImage?
    var uploadCaption: String = ""

    // Full screen viewer
    var selectedPhotoIndex: Int?

    // MARK: - Private

    private let eventId: String
    private let eventService = EventService.shared
    private var currentOffset: Int = 0
    private let pageSize: Int = 20

    // MARK: - Initialization

    init(eventId: String) {
        self.eventId = eventId
    }

    // MARK: - Public Methods

    /// Load photos
    func loadPhotos() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentOffset = 0

        do {
            let response = try await eventService.fetchPhotos(
                eventId: eventId,
                limit: pageSize,
                offset: 0
            )
            photos = response.photos
            photoCount = response.photoCount
            isGated = response.gated
            gatedMessage = response.message
            hasMore = response.pagination?.hasMore ?? false
            currentOffset = pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load more photos (pagination)
    func loadMoreIfNeeded(currentItem: EventPhoto) async {
        guard !isLoadingMore && hasMore else { return }

        let thresholdIndex = photos.index(photos.endIndex, offsetBy: -3)
        guard let itemIndex = photos.firstIndex(where: { $0.id == currentItem.id }),
              itemIndex >= thresholdIndex else {
            return
        }

        await loadMore()
    }

    /// Load next page
    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }

        isLoadingMore = true

        do {
            let response = try await eventService.fetchPhotos(
                eventId: eventId,
                limit: pageSize,
                offset: currentOffset
            )
            photos.append(contentsOf: response.photos)
            hasMore = response.pagination?.hasMore ?? false
            currentOffset += pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    /// Upload selected image
    func uploadPhoto() async {
        guard let image = selectedImage else { return }
        guard uploadState != .uploading(progress: 0) else { return }

        uploadState = .uploading(progress: 0)

        // Resize and compress image
        guard let resizedImage = resizeImage(image, maxDimension: 1920),
              let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            uploadState = .error("Failed to process image")
            return
        }

        uploadState = .uploading(progress: 0.3)

        do {
            let photo = try await eventService.uploadPhoto(
                eventId: eventId,
                imageData: imageData,
                caption: uploadCaption.isEmpty ? nil : uploadCaption
            )

            uploadState = .uploading(progress: 1.0)

            // Add to beginning of photos
            photos.insert(photo, at: 0)
            photoCount += 1

            // Reset upload state
            selectedImage = nil
            uploadCaption = ""
            uploadState = .success

            HapticFeedback.success.trigger()

            // Reset to idle after delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            uploadState = .idle
        } catch {
            uploadState = .error(error.localizedDescription)
            HapticFeedback.error.trigger()
        }
    }

    /// Delete a photo
    func deletePhoto(_ photo: EventPhoto) async {
        // Optimistically remove from UI
        let originalPhotos = photos
        let originalCount = photoCount

        photos.removeAll { $0.id == photo.id }
        photoCount = max(0, photoCount - 1)
        HapticFeedback.light.trigger()

        do {
            try await eventService.deletePhoto(eventId: eventId, photoId: photo.id)
            HapticFeedback.success.trigger()
        } catch {
            // Restore on failure
            photos = originalPhotos
            photoCount = originalCount
            errorMessage = error.localizedDescription
            HapticFeedback.error.trigger()
        }
    }

    /// Cancel upload
    func cancelUpload() {
        selectedImage = nil
        uploadCaption = ""
        uploadState = .idle
    }

    /// Refresh photos
    func refresh() async {
        await loadPhotos()
    }

    // MARK: - Computed Properties

    var isEmpty: Bool {
        photos.isEmpty && !isLoading
    }

    var isUploading: Bool {
        if case .uploading = uploadState {
            return true
        }
        return false
    }

    var canUpload: Bool {
        selectedImage != nil && !isUploading
    }

    // MARK: - Private Helpers

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size

        // Guard against invalid dimensions (prevent division by zero)
        guard size.width > 0 && size.height > 0 else { return nil }

        let aspectRatio = size.width / size.height

        var newSize: CGSize
        if size.width > size.height {
            if size.width <= maxDimension { return image }
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            if size.height <= maxDimension { return image }
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
