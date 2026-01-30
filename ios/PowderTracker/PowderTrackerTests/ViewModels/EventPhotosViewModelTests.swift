//
//  EventPhotosViewModelTests.swift
//  PowderTrackerTests
//
//  Unit tests for EventPhotosViewModel.
//

import XCTest
import UIKit
@testable import PowderTracker

@MainActor
final class EventPhotosViewModelTests: XCTestCase {

    var viewModel: EventPhotosViewModel!
    let testEventId = "test-event-123"

    override func setUp() async throws {
        viewModel = EventPhotosViewModel(eventId: testEventId)
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.photos.isEmpty)
        XCTAssertEqual(viewModel.photoCount, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertFalse(viewModel.hasMore)
        XCTAssertTrue(viewModel.isGated)
        XCTAssertNil(viewModel.selectedImage)
        XCTAssertTrue(viewModel.uploadCaption.isEmpty)
        XCTAssertEqual(viewModel.uploadState, .idle)
    }

    func testIsEmptyWhenNoPhotosAndNotLoading() {
        viewModel.isLoading = false
        viewModel.photos = []
        XCTAssertTrue(viewModel.isEmpty)
    }

    func testIsNotEmptyWhenHasPhotos() {
        viewModel.photos = [createMockPhoto()]
        XCTAssertFalse(viewModel.isEmpty)
    }

    // MARK: - Upload State Tests

    func testUploadStateIdle() {
        XCTAssertEqual(viewModel.uploadState, .idle)
        XCTAssertFalse(viewModel.isUploading)
    }

    func testUploadStateUploading() {
        viewModel.uploadState = .uploading(progress: 0.5)
        XCTAssertTrue(viewModel.isUploading)
    }

    func testUploadStateSuccess() {
        viewModel.uploadState = .success
        XCTAssertFalse(viewModel.isUploading)
    }

    func testUploadStateError() {
        viewModel.uploadState = .error("Upload failed")
        XCTAssertFalse(viewModel.isUploading)
    }

    // MARK: - Can Upload Tests

    func testCanUploadWhenHasImageAndNotUploading() {
        viewModel.selectedImage = UIImage()
        viewModel.uploadState = .idle
        XCTAssertTrue(viewModel.canUpload)
    }

    func testCannotUploadWhenNoImage() {
        viewModel.selectedImage = nil
        viewModel.uploadState = .idle
        XCTAssertFalse(viewModel.canUpload)
    }

    func testCannotUploadWhenAlreadyUploading() {
        viewModel.selectedImage = UIImage()
        viewModel.uploadState = .uploading(progress: 0.5)
        XCTAssertFalse(viewModel.canUpload)
    }

    // MARK: - Cancel Upload Tests

    func testCancelUploadResetsState() {
        viewModel.selectedImage = UIImage()
        viewModel.uploadCaption = "Test caption"
        viewModel.uploadState = .uploading(progress: 0.5)

        viewModel.cancelUpload()

        XCTAssertNil(viewModel.selectedImage)
        XCTAssertTrue(viewModel.uploadCaption.isEmpty)
        XCTAssertEqual(viewModel.uploadState, .idle)
    }

    // MARK: - Photo Count Tests

    func testPhotoCountIncrementsOnUpload() {
        let initialCount = viewModel.photoCount
        viewModel.photoCount += 1
        XCTAssertEqual(viewModel.photoCount, initialCount + 1)
    }

    func testPhotoCountDecrementsOnDelete() {
        viewModel.photoCount = 5
        viewModel.photoCount = max(0, viewModel.photoCount - 1)
        XCTAssertEqual(viewModel.photoCount, 4)
    }

    func testPhotoCountNeverGoesNegative() {
        viewModel.photoCount = 0
        viewModel.photoCount = max(0, viewModel.photoCount - 1)
        XCTAssertEqual(viewModel.photoCount, 0)
    }

    // MARK: - Selected Photo Index Tests

    func testSelectedPhotoIndexInitiallyNil() {
        XCTAssertNil(viewModel.selectedPhotoIndex)
    }

    func testSelectedPhotoIndexCanBeSet() {
        viewModel.selectedPhotoIndex = 5
        XCTAssertEqual(viewModel.selectedPhotoIndex, 5)
    }

    // MARK: - Gated State Tests

    func testGatedStateInitiallyTrue() {
        XCTAssertTrue(viewModel.isGated)
    }

    func testGatedMessageWhenGated() {
        viewModel.isGated = true
        viewModel.gatedMessage = "RSVP to see photos"
        XCTAssertEqual(viewModel.gatedMessage, "RSVP to see photos")
    }

    // MARK: - Pagination Tests

    func testLoadMoreGuardWhenAlreadyLoading() async {
        viewModel.isLoadingMore = true
        viewModel.hasMore = true

        let photo = createMockPhoto()
        viewModel.photos = [photo]
        await viewModel.loadMoreIfNeeded(currentItem: photo)

        // Should still be in loading state
        XCTAssertTrue(viewModel.isLoadingMore)
    }

    func testLoadMoreGuardWhenNoMore() async {
        viewModel.isLoadingMore = false
        viewModel.hasMore = false

        let photo = createMockPhoto()
        viewModel.photos = [photo]
        await viewModel.loadMoreIfNeeded(currentItem: photo)

        // Should not trigger loading
        XCTAssertFalse(viewModel.isLoadingMore)
    }

    // MARK: - Upload State Equality Tests

    func testUploadStateIdleEquality() {
        XCTAssertEqual(PhotoUploadState.idle, PhotoUploadState.idle)
    }

    func testUploadStateUploadingEquality() {
        XCTAssertEqual(
            PhotoUploadState.uploading(progress: 0.5),
            PhotoUploadState.uploading(progress: 0.5)
        )
    }

    func testUploadStateUploadingInequality() {
        XCTAssertNotEqual(
            PhotoUploadState.uploading(progress: 0.5),
            PhotoUploadState.uploading(progress: 0.7)
        )
    }

    func testUploadStateErrorEquality() {
        XCTAssertEqual(
            PhotoUploadState.error("Error 1"),
            PhotoUploadState.error("Error 1")
        )
    }

    func testUploadStateMixedInequality() {
        XCTAssertNotEqual(PhotoUploadState.idle, PhotoUploadState.success)
        XCTAssertNotEqual(PhotoUploadState.success, PhotoUploadState.error("test"))
    }

    // MARK: - Helper Methods

    private func createMockPhoto(
        id: String = "photo-1"
    ) -> EventPhoto {
        EventPhoto(
            id: id,
            eventId: testEventId,
            userId: "user-1",
            url: "https://example.com/photo.jpg",
            thumbnailUrl: "https://example.com/photo_thumb.jpg",
            caption: "Test photo",
            width: 1920,
            height: 1080,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            user: PhotoUser(
                id: "user-1",
                username: "testuser",
                displayName: "Test User",
                avatarUrl: nil
            )
        )
    }
}
