//
//  OnboardingProfile.swift
//  PowderTracker
//
//  Models for user onboarding flow.
//

import Foundation
import SwiftUI

// MARK: - Riding Style

enum RidingStyle: String, Codable, CaseIterable, Identifiable {
    case skier
    case snowboarder
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .skier: return "Skier"
        case .snowboarder: return "Snowboarder"
        case .both: return "Both"
        }
    }

    var description: String {
        switch self {
        case .skier: return "Two planks, one dream"
        case .snowboarder: return "Sideways is the way"
        case .both: return "Why choose?"
        }
    }

    var icon: String {
        switch self {
        case .skier: return "figure.skiing.downhill"
        case .snowboarder: return "figure.snowboarding"
        case .both: return "figure.skiing.crosscountry"
        }
    }

    var color: Color {
        switch self {
        case .skier: return Color(hex: "3B82F6") ?? .blue        // Classic ski blue
        case .snowboarder: return Color(hex: "F97316") ?? .orange // Snowboard orange
        case .both: return Color(hex: "8B5CF6") ?? .purple       // Purple for versatility
        }
    }

    /// Compact emoji representation for badges
    var emoji: String {
        switch self {
        case .skier: return "⛷️"
        case .snowboarder: return "🏂"
        case .both: return "🎿"
        }
    }
}

// MARK: - Experience Level

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced
    case expert

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "Just getting started"
        case .intermediate: return "Comfortable on blues"
        case .advanced: return "Tackling blacks"
        case .expert: return "Double blacks & beyond"
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "figure.skiing.downhill"
        case .intermediate: return "mountain.2"
        case .advanced: return "mountain.2.fill"
        case .expert: return "snowflake"
        }
    }

    /// Primary color for UI elements - matches traditional ski slope colors
    var color: Color {
        switch self {
        case .beginner: return Color(hex: "22C55E") ?? .green     // Green circle
        case .intermediate: return Color(hex: "3B82F6") ?? .blue  // Blue square
        case .advanced: return .black                              // Black diamond
        case .expert: return .black                                // Double black
        }
    }

    /// Secondary color for backgrounds and accents (lighter versions for visibility)
    var backgroundColor: Color {
        switch self {
        case .beginner: return Color(hex: "22C55E") ?? .green
        case .intermediate: return Color(hex: "3B82F6") ?? .blue
        case .advanced: return Color(hex: "374151") ?? .gray       // Dark gray for better visibility
        case .expert: return Color(hex: "1F2937") ?? .gray         // Darker gray
        }
    }
}

// MARK: - Terrain Type

enum TerrainType: String, Codable, CaseIterable, Identifiable {
    case groomers
    case moguls
    case trees
    case park
    case backcountry

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .groomers: return "Groomers"
        case .moguls: return "Moguls"
        case .trees: return "Trees"
        case .park: return "Park"
        case .backcountry: return "Backcountry"
        }
    }

    var icon: String {
        switch self {
        case .groomers: return "road.lanes"
        case .moguls: return "chart.line.uptrend.xyaxis"
        case .trees: return "tree.fill"
        case .park: return "figure.skiing.crosscountry"
        case .backcountry: return "mountain.2.fill"
        }
    }
}

// MARK: - Season Pass Type

enum SeasonPassType: String, Codable, CaseIterable, Identifiable {
    case none
    case ikon
    case epic
    case mountainSpecific = "mountain_specific"
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "No Pass"
        case .ikon: return "Ikon Pass"
        case .epic: return "Epic Pass"
        case .mountainSpecific: return "Mountain Specific"
        case .other: return "Other"
        }
    }

    var description: String {
        switch self {
        case .none: return "Day tickets only"
        case .ikon: return "Access to 50+ destinations"
        case .epic: return "Vail Resorts network"
        case .mountainSpecific: return "Single resort pass"
        case .other: return "Regional or other pass"
        }
    }

    var icon: String {
        switch self {
        case .none: return "ticket"
        case .ikon: return "globe.americas"
        case .epic: return "star.circle.fill"
        case .mountainSpecific: return "mountain.2"
        case .other: return "creditcard"
        }
    }

    var color: Color {
        switch self {
        case .none: return .gray
        case .ikon: return .orange
        case .epic: return .purple
        case .mountainSpecific: return .blue
        case .other: return .green
        }
    }
}

// MARK: - Onboarding Profile

struct OnboardingProfile: Codable {
    var displayName: String?
    var bio: String?
    var avatarUrl: String?
    var ridingStyle: RidingStyle?
    var experienceLevel: ExperienceLevel?
    var preferredTerrain: [TerrainType]
    var seasonPassType: SeasonPassType?
    var homeMountainId: String?

    init(
        displayName: String? = nil,
        bio: String? = nil,
        avatarUrl: String? = nil,
        ridingStyle: RidingStyle? = nil,
        experienceLevel: ExperienceLevel? = nil,
        preferredTerrain: [TerrainType] = [],
        seasonPassType: SeasonPassType? = nil,
        homeMountainId: String? = nil
    ) {
        self.displayName = displayName
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.ridingStyle = ridingStyle
        self.experienceLevel = experienceLevel
        self.preferredTerrain = preferredTerrain
        self.seasonPassType = seasonPassType
        self.homeMountainId = homeMountainId
    }

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case bio
        case avatarUrl = "avatar_url"
        case ridingStyle = "riding_style"
        case experienceLevel = "experience_level"
        case preferredTerrain = "preferred_terrain"
        case seasonPassType = "season_pass_type"
        case homeMountainId = "home_mountain_id"
    }

    // Custom encoding for preferred_terrain array
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encodeIfPresent(ridingStyle?.rawValue, forKey: .ridingStyle)
        try container.encodeIfPresent(experienceLevel?.rawValue, forKey: .experienceLevel)
        try container.encode(preferredTerrain.map { $0.rawValue }, forKey: .preferredTerrain)
        try container.encodeIfPresent(seasonPassType?.rawValue, forKey: .seasonPassType)
        try container.encodeIfPresent(homeMountainId, forKey: .homeMountainId)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)

        if let styleString = try container.decodeIfPresent(String.self, forKey: .ridingStyle) {
            ridingStyle = RidingStyle(rawValue: styleString)
        } else {
            ridingStyle = nil
        }

        if let levelString = try container.decodeIfPresent(String.self, forKey: .experienceLevel) {
            experienceLevel = ExperienceLevel(rawValue: levelString)
        } else {
            experienceLevel = nil
        }

        let terrainStrings = try container.decodeIfPresent([String].self, forKey: .preferredTerrain) ?? []
        preferredTerrain = terrainStrings.compactMap { TerrainType(rawValue: $0) }

        if let passString = try container.decodeIfPresent(String.self, forKey: .seasonPassType) {
            seasonPassType = SeasonPassType(rawValue: passString)
        } else {
            seasonPassType = nil
        }

        homeMountainId = try container.decodeIfPresent(String.self, forKey: .homeMountainId)
    }
}

// MARK: - Onboarding State

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case profileSetup = 1
    case aboutYou = 2
    case preferences = 3

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .profileSetup: return "Profile Setup"
        case .aboutYou: return "About You"
        case .preferences: return "Preferences"
        }
    }

    var isSkippable: Bool {
        switch self {
        case .welcome: return false
        default: return true
        }
    }
}

// MARK: - Onboarding Completion Status

struct OnboardingStatus: Codable {
    let hasCompletedOnboarding: Bool
    let onboardingCompletedAt: Date?
    let onboardingSkippedAt: Date?

    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding = "has_completed_onboarding"
        case onboardingCompletedAt = "onboarding_completed_at"
        case onboardingSkippedAt = "onboarding_skipped_at"
    }
}
