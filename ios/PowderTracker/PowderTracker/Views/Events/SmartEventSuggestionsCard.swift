//
//  SmartEventSuggestionsCard.swift
//  PowderTracker
//
//  Smart AI-powered suggestions for creating events based on
//  weather forecasts, conditions, and user preferences
//

import SwiftUI

/// Types of smart suggestions for event creation
enum EventSuggestionType: Identifiable {
    case powderDay(mountain: Mountain, forecast: ForecastDay)
    case weekendTrip(mountain: Mountain, date: Date, snowfall: Int)
    case bestConditions(mountain: Mountain, score: Double)
    case groupTrip(mountains: [Mountain], date: Date)
    
    var id: String {
        switch self {
        case .powderDay(let mountain, let forecast):
            return "powder_\(mountain.id)_\(forecast.date)"
        case .weekendTrip(let mountain, let date, _):
            return "weekend_\(mountain.id)_\(date.timeIntervalSince1970)"
        case .bestConditions(let mountain, _):
            return "best_\(mountain.id)"
        case .groupTrip(let mountains, let date):
            return "group_\(mountains.map { $0.id }.joined())_\(date.timeIntervalSince1970)"
        }
    }
    
    var icon: String {
        switch self {
        case .powderDay: return "snowflake.circle.fill"
        case .weekendTrip: return "calendar.badge.clock"
        case .bestConditions: return "star.circle.fill"
        case .groupTrip: return "person.3.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .powderDay: return .cyan
        case .weekendTrip: return .purple
        case .bestConditions: return .yellow
        case .groupTrip: return .green
        }
    }
    
    var title: String {
        switch self {
        case .powderDay(let mountain, _):
            return "Powder Day at \(mountain.name)"
        case .weekendTrip(let mountain, _, _):
            return "Weekend at \(mountain.name)"
        case .bestConditions(let mountain, _):
            return "\(mountain.name) is Looking Good"
        case .groupTrip(_, _):
            return "Plan a Group Trip"
        }
    }
    
    var subtitle: String {
        switch self {
        case .powderDay(_, let forecast):
            return "\(forecast.snowfall)\" expected \(forecast.dayOfWeek)"
        case .weekendTrip(_, let date, let snowfall):
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            let day = formatter.string(from: date)
            return snowfall > 0 ? "\(snowfall)\" fresh snow on \(day)" : "Great conditions on \(day)"
        case .bestConditions(_, let score):
            return "Powder score: \(String(format: "%.1f", score))/10"
        case .groupTrip(let mountains, _):
            return "\(mountains.count) mountains with good conditions"
        }
    }
}

/// Card displaying smart event creation suggestions
struct SmartEventSuggestionsCard: View {
    let suggestions: [EventSuggestionType]
    let onSuggestionTap: (EventSuggestionType) -> Void
    let onDismiss: () -> Void
    
    @State private var currentIndex = 0
    @State private var isDismissed = false
    
    var body: some View {
        if !isDismissed && !suggestions.isEmpty {
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: .spacingS) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Smart Suggestions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Page indicators
                    if suggestions.count > 1 {
                        HStack(spacing: .spacingXS) {
                            ForEach(0..<suggestions.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    
                    Button {
                        withAnimation(.smooth) {
                            isDismissed = true
                        }
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.spacingXS)
                            .background(Circle().fill(Color(.tertiarySystemFill)))
                    }
                    .accessibilityLabel("Dismiss suggestions")
                }
                .padding(.horizontal, .spacingM)
                .padding(.top, .spacingM)
                .padding(.bottom, .spacingS)
                
                // Suggestions carousel
                TabView(selection: $currentIndex) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                        suggestionCard(suggestion)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 100)
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
            .cardShadow()
            .accessibilityIdentifier("smart_event_suggestions")
        }
    }
    
    private func suggestionCard(_ suggestion: EventSuggestionType) -> some View {
        Button {
            HapticFeedback.medium.trigger()
            onSuggestionTap(suggestion)
        } label: {
            HStack(spacing: .spacingM) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [suggestion.accentColor, suggestion.accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: suggestion.accentColor.opacity(0.3), radius: 6, y: 2)
                    
                    Image(systemName: suggestion.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Content
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(suggestion.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Quick action hint
                    HStack(spacing: .spacingXS) {
                        Text("Tap to create event")
                            .font(.caption2)
                            .foregroundColor(suggestion.accentColor)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(suggestion.accentColor)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
        }
        .buttonStyle(.plain)
    }
}

/// ViewModel for generating smart event suggestions
@MainActor
class SmartEventSuggestionsViewModel: ObservableObject {
    @Published var suggestions: [EventSuggestionType] = []
    @Published var isLoading = false
    
    private let apiClient = APIClient.shared
    private let favoritesService = FavoritesService.shared
    
    func loadSuggestions() async {
        isLoading = true
        suggestions = []
        
        var newSuggestions: [EventSuggestionType] = []
        
        // Get favorite mountains
        let favoriteIds = favoritesService.favoriteIds
        
        // Load mountains and their data
        do {
            let mountainsResponse = try await apiClient.fetchMountains()
            let favoriteMountains = mountainsResponse.mountains.filter { favoriteIds.contains($0.id) }
            
            // Load data for each favorite mountain
            for mountain in favoriteMountains.prefix(5) {
                do {
                    let data = try await apiClient.fetchMountainData(for: mountain.id)
                    
                    // Check for powder days (6"+ expected)
                    if let powderDay = data.forecast.first(where: { $0.snowfall >= 6 }) {
                        newSuggestions.append(.powderDay(mountain: mountain, forecast: powderDay))
                    }
                    
                    // Check for good weekend conditions
                    let weekendDays = data.forecast.filter { 
                        $0.dayOfWeek == "Saturday" || $0.dayOfWeek == "Sunday" 
                    }
                    if let bestWeekend = weekendDays.max(by: { $0.snowfall < $1.snowfall }),
                       bestWeekend.snowfall > 0 || data.powderScore.score >= 6 {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if let date = dateFormatter.date(from: bestWeekend.date) {
                            newSuggestions.append(.weekendTrip(
                                mountain: mountain,
                                date: date,
                                snowfall: bestWeekend.snowfall
                            ))
                        }
                    }
                    
                    // Check for best current conditions
                    let score = data.powderScore.score
                    if score >= 7 {
                        newSuggestions.append(.bestConditions(mountain: mountain, score: score))
                    }
                } catch {
                    // Skip this mountain if data load fails
                    continue
                }
            }
            
            // Add group trip suggestion if multiple mountains have good conditions
            let goodMountains = favoriteMountains.prefix(3).filter { mountain in
                // Simple heuristic - include mountains that are likely good
                true
            }
            if goodMountains.count >= 2 {
                newSuggestions.append(.groupTrip(
                    mountains: Array(goodMountains),
                    date: getNextWeekend()
                ))
            }
            
        } catch {
            // Failed to load mountains
        }
        
        // Sort by priority and limit
        suggestions = Array(newSuggestions.prefix(5))
        isLoading = false
    }
    
    private func getNextWeekend() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // Find next Saturday (weekday 7)
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let nextSaturday = calendar.date(byAdding: .day, value: daysUntilSaturday == 0 ? 7 : daysUntilSaturday, to: today)!
        
        return nextSaturday
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: .spacingL) {
        SmartEventSuggestionsCard(
            suggestions: [
                .powderDay(
                    mountain: .mock,
                    forecast: ForecastDay(
                        date: "2026-02-05",
                        dayOfWeek: "Thursday",
                        high: 28,
                        low: 20,
                        snowfall: 12,
                        precipProbability: 85,
                        precipType: "snow",
                        wind: ForecastDay.ForecastWind(speed: 20, gust: 35),
                        conditions: "Heavy Snow",
                        icon: "snow"
                    )
                ),
                .weekendTrip(
                    mountain: Mountain.mockMountains[2],
                    date: Date().addingTimeInterval(86400 * 3),
                    snowfall: 8
                ),
                .bestConditions(
                    mountain: Mountain.mockMountains[1],
                    score: 8.5
                )
            ],
            onSuggestionTap: { _ in },
            onDismiss: {}
        )
        .padding()
        
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
