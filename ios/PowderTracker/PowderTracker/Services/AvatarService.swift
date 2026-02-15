//
//  AvatarService.swift
//  PowderTracker
//
//  Service for uploading and managing user avatar images.
//

import Foundation
import UIKit
import Supabase

@MainActor
class AvatarService: ObservableObject {

    static let shared = AvatarService()

    // MARK: - Configuration

    private let bucketName = "avatars"
    private let maxDimension: CGFloat = 512
    private let compressionQuality: CGFloat = 0.7
    private let maxFileSizeBytes = 1_048_576 // 1MB

    // MARK: - State

    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var lastError: String?

    // MARK: - Private

    private let supabase = SupabaseClientManager.shared.client

    private init() {}

    // MARK: - Public Methods

    /// Upload avatar image for the current user
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - userId: The user's auth ID (used for folder path)
    /// - Returns: The public URL of the uploaded avatar
    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        isUploading = true
        uploadProgress = 0
        lastError = nil

        defer {
            isUploading = false
        }

        // Step 1: Resize image
        uploadProgress = 0.1
        guard let resizedImage = resizeImage(image, maxDimension: maxDimension) else {
            throw AvatarError.resizeFailed
        }

        // Step 2: Compress to JPEG
        uploadProgress = 0.2
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw AvatarError.compressionFailed
        }

        // Verify file size
        if imageData.count > maxFileSizeBytes {
            // Try with lower quality
            guard let lowerQualityData = resizedImage.jpegData(compressionQuality: 0.5),
                  lowerQualityData.count <= maxFileSizeBytes else {
                throw AvatarError.fileTooLarge
            }
            // Use the lower quality data instead
            return try await uploadData(lowerQualityData, userId: userId)
        }

        return try await uploadData(imageData, userId: userId)
    }

    /// Delete the current user's avatar
    func deleteAvatar(userId: String) async throws {
        // List all avatars for this user
        let files = try await supabase.storage
            .from(bucketName)
            .list(path: userId)

        // Delete each one
        for file in files {
            let path = "\(userId)/\(file.name)"
            _ = try await supabase.storage
                .from(bucketName)
                .remove(paths: [path])
        }
    }

    /// Get the public URL for an avatar path
    func getPublicURL(path: String) -> URL? {
        try? supabase.storage
            .from(bucketName)
            .getPublicURL(path: path)
    }

    // MARK: - Private Methods

    private func uploadData(_ data: Data, userId: String) async throws -> String {
        uploadProgress = 0.3

        // Clean up old avatars before uploading new one
        try? await deleteAvatar(userId: userId)

        // Generate unique filename with timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "avatar_\(timestamp).jpg"
        let filePath = "\(userId)/\(fileName)"

        uploadProgress = 0.5

        // Upload to Supabase Storage
        try await supabase.storage
            .from(bucketName)
            .upload(
                path: filePath,
                file: data,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        uploadProgress = 0.9

        // Get public URL
        guard let publicURL = getPublicURL(path: filePath) else {
            throw AvatarError.urlGenerationFailed
        }

        uploadProgress = 1.0

        return publicURL.absoluteString
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size

        // Check if resize is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        // Use UIGraphicsImageRenderer for efficient resizing
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
    }
}

// MARK: - Avatar Error

enum AvatarError: LocalizedError {
    case resizeFailed
    case compressionFailed
    case fileTooLarge
    case uploadFailed(String)
    case urlGenerationFailed

    var errorDescription: String? {
        switch self {
        case .resizeFailed:
            return "Failed to resize image"
        case .compressionFailed:
            return "Failed to compress image"
        case .fileTooLarge:
            return "Image is too large. Please select a smaller image."
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .urlGenerationFailed:
            return "Failed to generate avatar URL"
        }
    }
}
