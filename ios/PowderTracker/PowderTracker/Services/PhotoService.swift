import Foundation
import UIKit
import Supabase
import Storage

@MainActor
class PhotoService: ObservableObject {
    static let shared = PhotoService()

    private let supabase: SupabaseClient

    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var error: String?

    private init() {
        guard let supabaseURL = URL(string: AppConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL configuration: \(AppConfig.supabaseURL)")
        }
        supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    // MARK: - Upload Photo

    func uploadPhoto(
        image: UIImage,
        mountainId: String,
        webcamId: String? = nil,
        caption: String? = nil
    ) async throws -> Photo {
        isUploading = true
        uploadProgress = 0.0
        error = nil

        defer {
            isUploading = false
            uploadProgress = 0.0
        }

        // Get current user
        let user = try await supabase.auth.session.user

        // Compress image to JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "PhotoService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to compress image"
            ])
        }

        // Validate file size (5MB)
        if imageData.count > 5 * 1024 * 1024 {
            throw NSError(domain: "PhotoService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Image too large. Maximum size is 5MB."
            ])
        }

        // Generate unique filename
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let randomStr = UUID().uuidString.prefix(8)
        let fileName = "\(user.id.uuidString)/\(mountainId)/\(timestamp)-\(randomStr).jpg"

        uploadProgress = 0.3

        // Upload to Supabase Storage
        _ = try await supabase.storage
            .from("user-photos")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: false
                )
            )

        uploadProgress = 0.6

        // Get public URL
        let publicURL = try supabase.storage
            .from("user-photos")
            .getPublicURL(path: fileName)

        uploadProgress = 0.8

        // Create database record
        struct PhotoInsert: Encodable {
            let user_id: String
            let mountain_id: String
            let webcam_id: String?
            let s3_key: String
            let s3_bucket: String
            let cloudfront_url: String
            let thumbnail_url: String
            let caption: String?
            let taken_at: String
            let file_size_bytes: Int
            let mime_type: String
        }

        let photoRecord = PhotoInsert(
            user_id: user.id.uuidString,
            mountain_id: mountainId,
            webcam_id: webcamId,
            s3_key: fileName,
            s3_bucket: "user-photos",
            cloudfront_url: publicURL.absoluteString,
            thumbnail_url: publicURL.absoluteString,
            caption: caption,
            taken_at: ISO8601DateFormatter().string(from: Date()),
            file_size_bytes: imageData.count,
            mime_type: "image/jpeg"
        )

        let response: Photo = try await supabase
            .from("user_photos")
            .insert(photoRecord)
            .select()
            .single()
            .execute()
            .value

        uploadProgress = 1.0

        return response
    }

    // MARK: - Fetch Photos

    func fetchPhotos(
        for mountainId: String,
        webcamId: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Photo] {
        var query = supabase
            .from("user_photos")
            .select(
                """
                *,
                users:user_id (
                    username,
                    display_name,
                    avatar_url
                )
                """
            )
            .eq("mountain_id", value: mountainId)
            .eq("is_approved", value: true)

        // Add webcam filter if provided
        if let webcamId = webcamId {
            query = query.eq("webcam_id", value: webcamId)
        }

        let response: [Photo] = try await query
            .order("taken_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return response
    }

    // MARK: - Delete Photo

    func deletePhoto(_ photoId: String) async throws {
        // Get photo details
        let photo: Photo = try await supabase
            .from("user_photos")
            .select()
            .eq("id", value: photoId)
            .single()
            .execute()
            .value

        // Verify ownership
        let currentUser = try await supabase.auth.session.user
        guard photo.userId == currentUser.id.uuidString else {
            throw NSError(domain: "PhotoService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "You can only delete your own photos"
            ])
        }

        // Delete from storage
        _ = try await supabase.storage
            .from(photo.s3Bucket)
            .remove(paths: [photo.s3Key])

        // Delete from database
        try await supabase
            .from("user_photos")
            .delete()
            .eq("id", value: photoId)
            .execute()
    }
}
