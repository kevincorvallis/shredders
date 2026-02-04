import SwiftUI

/// Displays Apple Weather attribution as required by WeatherKit terms
/// Must be displayed whenever WeatherKit data is shown
struct WeatherAttributionView: View {
    let weatherKitService = WeatherKitService.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Link(destination: weatherKitService.attribution.link) {
            HStack(spacing: 4) {
                Image(systemName: "applelogo")
                    .font(.caption2)
                Text("Weather")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
}

/// Compact inline attribution for use in weather sections
struct WeatherAttributionInline: View {
    let weatherKitService = WeatherKitService.shared
    
    var body: some View {
        Link(destination: weatherKitService.attribution.link) {
            HStack(spacing: 2) {
                Image(systemName: "applelogo")
                    .font(.caption2)
                Text("Weather")
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
    }
}

/// Full attribution with "Powered by" text
struct WeatherAttributionFull: View {
    let weatherKitService = WeatherKitService.shared
    
    var body: some View {
        Link(destination: weatherKitService.attribution.link) {
            HStack(spacing: 4) {
                Text("Powered by")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 2) {
                    Image(systemName: "applelogo")
                        .font(.caption)
                    Text("Weather")
                        .font(.caption)
                }
                .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WeatherAttributionView()
        WeatherAttributionInline()
        WeatherAttributionFull()
    }
    .padding()
}
