//
//  EventPhoto.swift
//  PowderTracker
//
//  Model for event photos with gallery support.
//

import Foundation
import SwiftUI

// MARK: - Event Photo Models

struct EventPhoto: Codable, Identifiable {
    let id: String
    let eventId: String
    let userId: String
    let url: String
    let thumbnailUrl: String?
    let caption: String?
    let width: Int?
    let height: Int?
    let createdAt: String
    let user: EventPhotoUser?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case userId
        case url
        case thumbnailUrl
        case caption
        case width
        case height
        case createdAt
        case user
    }

    /// Best URL for displaying (thumbnail if available, otherwise full)
    var displayUrl: String {
        thumbnailUrl ?? url
    }

    /// Formatted relative time
    var relativeTime: String {
        guard let date = DateFormatters.parseISO8601(createdAt) else { return createdAt }
        return DateFormatters.relativeTimeString(from: date)
    }

    /// Aspect ratio for layout (default to square if unknown)
    var aspectRatio: CGFloat {
        guard let width = width, let height = height, height > 0 else {
            return 1.0
        }
        return CGFloat(width) / CGFloat(height)
    }
}

// MARK: - Photo User

struct EventPhotoUser: Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName
        case avatarUrl
    }

    var displayNameOrUsername: String {
        displayName ?? username
    }
}

// MARK: - API Response Types

struct EventPhotosResponse: Codable {
    let photos: [EventPhoto]
    let photoCount: Int
    let gated: Bool
    let message: String?
    let pagination: PhotoPagination?
}

struct PhotoPagination: Codable {
    let limit: Int
    let offset: Int
    let hasMore: Bool
}

struct UploadPhotoResponse: Codable {
    let photo: EventPhoto
}

struct DeletePhotoResponse: Codable {
    let message: String
}

// MARK: - Upload State

enum PhotoUploadState: Equatable {
    case idle
    case selecting
    case uploading(progress: Double)
    case success
    case error(String)

    static func == (lhs: PhotoUploadState, rhs: PhotoUploadState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.selecting, .selecting), (.success, .success):
            return true
        case (.uploading(let p1), .uploading(let p2)):
            return p1 == p2
        case (.error(let e1), .error(let e2)):
            return e1 == e2
        default:
            return false
        }
    }
}
