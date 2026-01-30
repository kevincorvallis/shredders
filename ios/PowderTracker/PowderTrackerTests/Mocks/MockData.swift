//
//  MockData.swift
//  PowderTrackerTests
//
//  Factory methods for creating mock data in tests.
//

import Foundation
@testable import PowderTracker

// MARK: - Mountain Mocks

extension Mountain {
    static func mock(
        id: String = "mock-mountain-1",
        name: String = "Mock Mountain",
        shortName: String = "Mock",
        lat: Double = 47.0,
        lng: Double = -121.0,
        baseElevation: Int = 4000,
        summitElevation: Int = 7000,
        region: String = "washington",
        color: String = "#3b82f6",
        website: String = "https://example.com",
        hasSnotel: Bool = true,
        webcamCount: Int = 3,
        logo: String? = nil,
        isOpen: Bool = true,
        percentOpen: Int? = 85,
        liftsOpen: String? = "8/10",
        runsOpen: String? = "70/82",
        statusMessage: String? = nil,
        passType: PassType? = nil
    ) -> Mountain {
        Mountain(
            id: id,
            name: name,
            shortName: shortName,
            location: MountainLocation(lat: lat, lng: lng),
            elevation: MountainElevation(base: baseElevation, summit: summitElevation),
            region: region,
            color: color,
            website: website,
            hasSnotel: hasSnotel,
            webcamCount: webcamCount,
            logo: logo,
            status: MountainStatus(
                isOpen: isOpen,
                percentOpen: percentOpen,
                liftsOpen: liftsOpen,
                runsOpen: runsOpen,
                message: statusMessage,
                lastUpdated: nil
            ),
            passType: passType
        )
    }

    static func mockEpicPass(id: String = "epic-mountain") -> Mountain {
        mock(
            id: id,
            name: "Epic Mountain Resort",
            shortName: "Epic",
            passType: .epic
        )
    }

    static func mockIkonPass(id: String = "ikon-mountain") -> Mountain {
        mock(
            id: id,
            name: "Ikon Mountain Resort",
            shortName: "Ikon",
            passType: .ikon
        )
    }

    static func mockIndependent(id: String = "indie-mountain") -> Mountain {
        mock(
            id: id,
            name: "Independent Mountain",
            shortName: "Indie",
            passType: .independent
        )
    }

    static func mockList(count: Int = 5) -> [Mountain] {
        (0..<count).map { i in
            mock(
                id: "mountain-\(i)",
                name: "Mountain \(i + 1)",
                shortName: "Mt\(i + 1)"
            )
        }
    }
}

// MARK: - Event Mocks

extension Event {
    static func mock(
        id: String = "mock-event-1",
        creatorId: String = "user-1",
        mountainId: String = "baker",
        mountainName: String? = "Mt. Baker",
        title: String = "Powder Day Meetup",
        notes: String? = "Let's hit the slopes!",
        eventDate: String? = nil, // Defaults to tomorrow
        departureTime: String? = "08:00:00",
        departureLocation: String? = "Seattle",
        skillLevel: SkillLevel? = .intermediate,
        carpoolAvailable: Bool = true,
        carpoolSeats: Int? = 4,
        status: EventStatus = .active,
        attendeeCount: Int = 5,
        goingCount: Int = 4,
        maybeCount: Int = 1,
        creatorUsername: String = "skimaster",
        creatorDisplayName: String? = "Ski Master",
        creatorAvatarUrl: String? = nil,
        userRSVPStatus: RSVPStatus? = nil,
        isCreator: Bool? = false
    ) -> Event {
        let date = eventDate ?? {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: tomorrow)
        }()

        return Event(
            id: id,
            creatorId: creatorId,
            mountainId: mountainId,
            mountainName: mountainName,
            title: title,
            notes: notes,
            eventDate: date,
            departureTime: departureTime,
            departureLocation: departureLocation,
            skillLevel: skillLevel,
            carpoolAvailable: carpoolAvailable,
            carpoolSeats: carpoolSeats,
            status: status,
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            attendeeCount: attendeeCount,
            goingCount: goingCount,
            maybeCount: maybeCount,
            creator: EventUser(
                id: creatorId,
                username: creatorUsername,
                displayName: creatorDisplayName,
                avatarUrl: creatorAvatarUrl
            ),
            userRSVPStatus: userRSVPStatus,
            isCreator: isCreator
        )
    }

    static func mockPastEvent(id: String = "past-event") -> Event {
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return mock(
            id: id,
            title: "Past Ski Day",
            eventDate: formatter.string(from: pastDate),
            status: .completed
        )
    }

    static func mockWithRSVP(_ status: RSVPStatus, id: String = "rsvp-event") -> Event {
        mock(
            id: id,
            userRSVPStatus: status
        )
    }

    static func mockFullCapacity(id: String = "full-event") -> Event {
        mock(
            id: id,
            title: "Full Event",
            carpoolAvailable: true,
            carpoolSeats: 4,
            attendeeCount: 10,
            goingCount: 10,
            maybeCount: 0
        )
    }

    static func mockList(count: Int = 5) -> [Event] {
        (0..<count).map { i in
            mock(
                id: "event-\(i)",
                title: "Event \(i + 1)"
            )
        }
    }
}

// MARK: - EventWithDetails Mocks

extension EventWithDetails {
    static func mock(
        id: String = "mock-event-detail-1",
        creatorId: String = "user-1",
        mountainId: String = "baker",
        mountainName: String? = "Mt. Baker",
        title: String = "Powder Day Meetup",
        notes: String? = "Let's hit the slopes!",
        eventDate: String? = nil,
        departureTime: String? = "08:00:00",
        departureLocation: String? = "Seattle",
        skillLevel: SkillLevel? = .intermediate,
        carpoolAvailable: Bool = true,
        carpoolSeats: Int? = 4,
        status: EventStatus = .active,
        attendeeCount: Int = 5,
        goingCount: Int = 4,
        maybeCount: Int = 1,
        commentCount: Int? = 3,
        photoCount: Int? = 5,
        creatorUsername: String = "skimaster",
        creatorDisplayName: String? = "Ski Master",
        userRSVPStatus: RSVPStatus? = nil,
        isCreator: Bool? = false,
        attendees: [EventAttendee] = [],
        conditions: EventConditions? = nil,
        inviteToken: String? = nil
    ) -> EventWithDetails {
        let date = eventDate ?? {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: tomorrow)
        }()

        return EventWithDetails(
            id: id,
            creatorId: creatorId,
            mountainId: mountainId,
            mountainName: mountainName,
            title: title,
            notes: notes,
            eventDate: date,
            departureTime: departureTime,
            departureLocation: departureLocation,
            skillLevel: skillLevel,
            carpoolAvailable: carpoolAvailable,
            carpoolSeats: carpoolSeats,
            status: status,
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            attendeeCount: attendeeCount,
            goingCount: goingCount,
            maybeCount: maybeCount,
            commentCount: commentCount,
            photoCount: photoCount,
            creator: EventUser(
                id: creatorId,
                username: creatorUsername,
                displayName: creatorDisplayName,
                avatarUrl: nil
            ),
            userRSVPStatus: userRSVPStatus,
            isCreator: isCreator,
            attendees: attendees,
            conditions: conditions,
            inviteToken: inviteToken
        )
    }
}

// MARK: - User Mocks

extension UserProfile {
    static func mock(
        id: String = "mock-user-1",
        authUserId: String = "auth-user-1",
        username: String = "testuser",
        email: String = "test@example.com",
        displayName: String? = "Test User",
        bio: String? = nil,
        avatarUrl: String? = nil,
        homeMountainId: String? = "baker",
        isActive: Bool = true,
        hasCompletedOnboarding: Bool? = true,
        experienceLevel: String? = "intermediate",
        preferredTerrain: [String]? = ["groomers", "trees"],
        seasonPassType: String? = "ikon"
    ) -> UserProfile {
        UserProfile(
            id: id,
            authUserId: authUserId,
            username: username,
            email: email,
            displayName: displayName,
            bio: bio,
            avatarUrl: avatarUrl,
            homeMountainId: homeMountainId,
            createdAt: Date(),
            updatedAt: Date(),
            lastLoginAt: Date(),
            isActive: isActive,
            hasCompletedOnboarding: hasCompletedOnboarding,
            experienceLevel: experienceLevel,
            preferredTerrain: preferredTerrain,
            seasonPassType: seasonPassType,
            onboardingCompletedAt: hasCompletedOnboarding == true ? Date() : nil,
            onboardingSkippedAt: nil
        )
    }

    static func mockBeginner() -> UserProfile {
        mock(
            displayName: "Beginner Skier",
            experienceLevel: "beginner",
            preferredTerrain: ["groomers"]
        )
    }

    static func mockExpert() -> UserProfile {
        mock(
            displayName: "Expert Skier",
            experienceLevel: "expert",
            preferredTerrain: ["trees", "moguls", "backcountry"]
        )
    }

    static func mockNewUser() -> UserProfile {
        mock(
            displayName: nil,
            hasCompletedOnboarding: false,
            experienceLevel: nil,
            preferredTerrain: nil,
            seasonPassType: nil
        )
    }
}

// MARK: - Event Comment Mocks

extension EventComment {
    static func mock(
        id: String = "mock-comment-1",
        eventId: String = "event-1",
        userId: String = "user-1",
        content: String = "This is a test comment",
        parentId: String? = nil,
        username: String = "commenter",
        displayName: String? = "Test Commenter",
        avatarUrl: String? = nil,
        replies: [EventComment]? = nil
    ) -> EventComment {
        EventComment(
            id: id,
            eventId: eventId,
            userId: userId,
            content: content,
            parentId: parentId,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            user: EventCommentUser(
                id: userId,
                username: username,
                displayName: displayName,
                avatarUrl: avatarUrl
            ),
            replies: replies
        )
    }

    static func mockWithReplies(replyCount: Int = 3) -> EventComment {
        let replies = (0..<replyCount).map { i in
            mock(
                id: "reply-\(i)",
                parentId: "mock-comment-1",
                content: "Reply \(i + 1)"
            )
        }
        return mock(replies: replies)
    }

    static func mockList(count: Int = 5) -> [EventComment] {
        (0..<count).map { i in
            mock(
                id: "comment-\(i)",
                content: "Comment \(i + 1)"
            )
        }
    }
}

// MARK: - Event Photo Mocks

extension EventPhoto {
    static func mock(
        id: String = "mock-photo-1",
        eventId: String = "event-1",
        userId: String = "user-1",
        url: String = "https://example.com/photo.jpg",
        thumbnailUrl: String? = "https://example.com/photo-thumb.jpg",
        caption: String? = nil,
        width: Int? = 1920,
        height: Int? = 1080,
        username: String = "photographer",
        displayName: String? = "Test Photographer"
    ) -> EventPhoto {
        EventPhoto(
            id: id,
            eventId: eventId,
            userId: userId,
            url: url,
            thumbnailUrl: thumbnailUrl,
            caption: caption,
            width: width,
            height: height,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            user: EventPhotoUser(
                id: userId,
                username: username,
                displayName: displayName,
                avatarUrl: nil
            )
        )
    }

    static func mockSquare() -> EventPhoto {
        mock(width: 1080, height: 1080)
    }

    static func mockPortrait() -> EventPhoto {
        mock(width: 1080, height: 1920)
    }

    static func mockList(count: Int = 10) -> [EventPhoto] {
        (0..<count).map { i in
            mock(
                id: "photo-\(i)",
                url: "https://example.com/photo-\(i).jpg"
            )
        }
    }
}

// MARK: - Forecast Mocks

extension ForecastDay {
    static func mock(
        date: String? = nil,
        dayOfWeek: String = "Mon",
        high: Int = 32,
        low: Int = 24,
        snowfall: Int = 6,
        precipProbability: Int = 80,
        precipType: String = "snow",
        windSpeed: Int = 12,
        windGust: Int = 25,
        conditions: String = "Snow showers",
        icon: String = "snow"
    ) -> ForecastDay {
        let dateStr = date ?? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: Date())
        }()

        return ForecastDay(
            date: dateStr,
            dayOfWeek: dayOfWeek,
            high: high,
            low: low,
            snowfall: snowfall,
            precipProbability: precipProbability,
            precipType: precipType,
            wind: ForecastWind(speed: windSpeed, gust: windGust),
            conditions: conditions,
            icon: icon
        )
    }

    static func mockPowderDay() -> ForecastDay {
        mock(
            snowfall: 12,
            precipProbability: 95,
            conditions: "Heavy snow",
            icon: "snow"
        )
    }

    static func mockClearDay() -> ForecastDay {
        mock(
            high: 38,
            low: 28,
            snowfall: 0,
            precipProbability: 10,
            precipType: "none",
            conditions: "Clear",
            icon: "sun"
        )
    }

    static func mockWeekForecast() -> [ForecastDay] {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return days.enumerated().map { index, day in
            let date = Calendar.current.date(byAdding: .day, value: index, to: Date())!
            return mock(
                date: formatter.string(from: date),
                dayOfWeek: day,
                snowfall: [6, 0, 2, 8, 12, 4, 0][index]
            )
        }
    }
}

// MARK: - Mountain Conditions Mocks

struct MockMountainConditions {
    let snowDepth: Int
    let newSnow24h: Int
    let newSnow48h: Int
    let temperature: Int
    let liftsOpen: Int
    let liftsTotal: Int
    let trailsOpen: Int
    let trailsTotal: Int

    static func mock(
        snowDepth: Int = 85,
        newSnow24h: Int = 6,
        newSnow48h: Int = 14,
        temperature: Int = 28,
        liftsOpen: Int = 8,
        liftsTotal: Int = 10,
        trailsOpen: Int = 70,
        trailsTotal: Int = 82
    ) -> MockMountainConditions {
        MockMountainConditions(
            snowDepth: snowDepth,
            newSnow24h: newSnow24h,
            newSnow48h: newSnow48h,
            temperature: temperature,
            liftsOpen: liftsOpen,
            liftsTotal: liftsTotal,
            trailsOpen: trailsOpen,
            trailsTotal: trailsTotal
        )
    }

    static func mockPowderConditions() -> MockMountainConditions {
        mock(
            snowDepth: 120,
            newSnow24h: 18,
            newSnow48h: 32,
            temperature: 26
        )
    }

    static func mockPoorConditions() -> MockMountainConditions {
        mock(
            snowDepth: 40,
            newSnow24h: 0,
            newSnow48h: 0,
            temperature: 38,
            liftsOpen: 4,
            trailsOpen: 35
        )
    }
}
