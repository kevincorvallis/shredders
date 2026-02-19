import SwiftUI

/// Horizontally scrollable snow forecast section showing one card per mountain.
/// Each card displays an OpenSnow-style bar chart with daily snowfall and period totals.
struct SnowForecastScrollView: View {
    let favorites: [(mountain: Mountain, forecast: [ForecastDay])]
    var onMountainTap: ((Mountain) -> Void)? = nil

    @State private var selectedRange: ForecastRange = .tenDays

    enum ForecastRange: String, CaseIterable {
        case sevenDays = "7D"
        case tenDays = "10D"

        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .tenDays: return 10
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Section header with range toggle
            header

            if favorites.isEmpty {
                emptyState
            } else {
                // Horizontal scroll of cards
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: .spacingM) {
                        ForEach(sortedFavorites, id: \.mountain.id) { fav in
                            SnowForecastCardView(
                                mountain: fav.mountain,
                                forecast: fav.forecast,
                                daysToShow: selectedRange.days,
                                onTap: { onMountainTap?(fav.mountain) }
                            )
                        }
                    }
                    .padding(.horizontal, .spacingL)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, 0, for: .scrollContent)
            }
        }
    }

    /// Sort favorites by total snowfall (most snow first)
    private var sortedFavorites: [(mountain: Mountain, forecast: [ForecastDay])] {
        favorites.sorted { a, b in
            let aTotal = a.forecast.prefix(selectedRange.days).reduce(0) { $0 + $1.snowfall }
            let bTotal = b.forecast.prefix(selectedRange.days).reduce(0) { $0 + $1.snowfall }
            return aTotal > bTotal
        }
    }

    private var header: some View {
        HStack {
            SectionHeaderView(title: "Snow Forecast", icon: "snowflake", iconColor: .blue)

            Spacer()

            Picker("Range", selection: $selectedRange) {
                ForEach(ForecastRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
        }
        .padding(.horizontal, .spacingL)
    }

    private var emptyState: some View {
        VStack(spacing: .spacingM) {
            Image(systemName: "snowflake")
                .font(.largeTitle)
                .foregroundStyle(.blue.opacity(0.4))

            Text("Add favorites to see forecasts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

#Preview {
    ScrollView {
        SnowForecastScrollView(
            favorites: [
                (mountain: .mock, forecast: ForecastDay.mockWeek),
            ]
        )
    }
    .background(Color(.systemGroupedBackground))
}
