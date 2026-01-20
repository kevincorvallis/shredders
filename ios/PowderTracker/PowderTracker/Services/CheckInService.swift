import Foundation
import Supabase

@MainActor
@Observable
class CheckInService {
    static let shared = CheckInService()

    private let supabase: SupabaseClient

    private init() {
        guard let supabaseURL = URL(string: AppConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL configuration: \(AppConfig.supabaseURL)")
        }
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    /// Fetch check-ins for a mountain
    func fetchCheckIns(
        for mountainId: String,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [CheckIn] {
        let response: [CheckIn] = try await supabase.from("check_ins")
            .select("""
                *,
                user:user_id (
                    id,
                    username,
                    display_name,
                    avatar_url
                )
            """)
            .eq("mountain_id", value: mountainId)
            .eq("is_public", value: true)
            .order("check_in_time", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return response
    }

    /// Fetch check-ins for a user
    func fetchUserCheckIns(
        userId: String,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [CheckIn] {
        let response: [CheckIn] = try await supabase.from("check_ins")
            .select("""
                *,
                user:user_id (
                    id,
                    username,
                    display_name,
                    avatar_url
                )
            """)
            .eq("user_id", value: userId)
            .order("check_in_time", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return response
    }

    /// Create a new check-in
    func createCheckIn(
        mountainId: String,
        tripReport: String?,
        rating: Int?,
        snowQuality: String?,
        crowdLevel: String?,
        isPublic: Bool = true
    ) async throws -> CheckIn {
        // Get current user
        guard let user = try? await supabase.auth.session.user else {
            throw CheckInError.notAuthenticated
        }

        // Validate trip report length
        if let tripReport = tripReport, tripReport.count > 5000 {
            throw CheckInError.tripReportTooLong
        }

        // Validate rating
        if let rating = rating, rating < 1 || rating > 5 {
            throw CheckInError.invalidRating
        }

        // Create check-in insert struct
        struct CheckInInsert: Encodable {
            let user_id: String
            let mountain_id: String
            let check_in_time: String
            let trip_report: String?
            let rating: Int?
            let snow_quality: String?
            let crowd_level: String?
            let is_public: Bool
        }

        let checkInData = CheckInInsert(
            user_id: user.id.uuidString,
            mountain_id: mountainId,
            check_in_time: ISO8601DateFormatter().string(from: Date()),
            trip_report: tripReport,
            rating: rating,
            snow_quality: snowQuality,
            crowd_level: crowdLevel,
            is_public: isPublic
        )

        let response: CheckIn = try await supabase.from("check_ins")
            .insert(checkInData)
            .select("""
                *,
                user:user_id (
                    id,
                    username,
                    display_name,
                    avatar_url
                )
            """)
            .single()
            .execute()
            .value

        return response
    }

    /// Update a check-in (owner only)
    func updateCheckIn(
        id: String,
        tripReport: String?,
        rating: Int?,
        snowQuality: String?,
        crowdLevel: String?,
        isPublic: Bool?
    ) async throws -> CheckIn {
        // Get current user
        guard let user = try? await supabase.auth.session.user else {
            throw CheckInError.notAuthenticated
        }

        // Fetch existing check-in to verify ownership
        let existingCheckIn: CheckIn = try await supabase.from("check_ins")
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()
            .value

        guard existingCheckIn.userId == user.id.uuidString else {
            throw CheckInError.notOwner
        }

        // Validate trip report length
        if let tripReport = tripReport, tripReport.count > 5000 {
            throw CheckInError.tripReportTooLong
        }

        // Validate rating
        if let rating = rating, rating < 1 || rating > 5 {
            throw CheckInError.invalidRating
        }

        // Build update struct (only non-nil fields)
        struct CheckInUpdate: Encodable {
            let trip_report: String?
            let rating: Int?
            let snow_quality: String?
            let crowd_level: String?
            let is_public: Bool?

            init(
                tripReport: String? = nil,
                rating: Int? = nil,
                snowQuality: String? = nil,
                crowdLevel: String? = nil,
                isPublic: Bool? = nil
            ) {
                self.trip_report = tripReport
                self.rating = rating
                self.snow_quality = snowQuality
                self.crowd_level = crowdLevel
                self.is_public = isPublic
            }
        }

        let updateData = CheckInUpdate(
            tripReport: tripReport,
            rating: rating,
            snowQuality: snowQuality,
            crowdLevel: crowdLevel,
            isPublic: isPublic
        )

        let response: CheckIn = try await supabase.from("check_ins")
            .update(updateData)
            .eq("id", value: id)
            .select("""
                *,
                user:user_id (
                    id,
                    username,
                    display_name,
                    avatar_url
                )
            """)
            .single()
            .execute()
            .value

        return response
    }

    /// Delete a check-in (owner only)
    func deleteCheckIn(id: String) async throws {
        // Get current user
        guard let user = try? await supabase.auth.session.user else {
            throw CheckInError.notAuthenticated
        }

        // Fetch existing check-in to verify ownership
        let existingCheckIn: CheckIn = try await supabase.from("check_ins")
            .select("user_id")
            .eq("id", value: id)
            .single()
            .execute()
            .value

        guard existingCheckIn.userId == user.id.uuidString else {
            throw CheckInError.notOwner
        }

        // Delete check-in
        try await supabase.from("check_ins")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

enum CheckInError: LocalizedError {
    case notAuthenticated
    case tripReportTooLong
    case invalidRating
    case notOwner

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to check in"
        case .tripReportTooLong:
            return "Trip report must be less than 5000 characters"
        case .invalidRating:
            return "Rating must be between 1 and 5"
        case .notOwner:
            return "You can only edit or delete your own check-ins"
        }
    }
}
