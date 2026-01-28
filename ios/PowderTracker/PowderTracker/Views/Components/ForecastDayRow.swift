import SwiftUI

struct ForecastDayRow: View {
    let day: ForecastDay
    var isToday: Bool = false
    var mountainName: String? = nil
    var onPlanTrip: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            // Day
            VStack(alignment: .leading) {
                Text(day.dayOfWeek)
                    .font(.headline)
                    .foregroundColor(isToday ? .blue : .primary)
                if isToday {
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .frame(width: 50, alignment: .leading)

            // Icon
            Text(day.iconEmoji)
                .font(.title2)

            // Snowfall
            HStack(spacing: 4) {
                if day.snowfall > 0 {
                    Image(systemName: "snowflake")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("\(day.snowfall)\"")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                } else {
                    Text("—")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 50)

            Spacer()

            // Conditions
            Text(day.conditions)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            // Temps
            HStack(spacing: 4) {
                Text("\(day.high)°")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("/")
                    .foregroundColor(.secondary)
                Text("\(day.low)°")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(forecastAccessibilityLabel)
        .contextMenu {
            // Plan trip action
            if let onPlanTrip = onPlanTrip {
                Button {
                    HapticFeedback.light.trigger()
                    onPlanTrip()
                } label: {
                    Label("Plan trip for \(day.dayOfWeek)", systemImage: "calendar.badge.plus")
                }
            }

            // Share forecast
            Button {
                HapticFeedback.light.trigger()
            } label: {
                Label("Share forecast", systemImage: "square.and.arrow.up")
            }

            Divider()

            // Weather details (info only)
            Label("\(day.conditions)", systemImage: weatherIcon)
            Label("High: \(day.high)° / Low: \(day.low)°", systemImage: "thermometer")
            if day.snowfall > 0 {
                Label("Expected: \(day.snowfall)\" snow", systemImage: "snowflake")
            }
            Label("Wind: \(day.wind.speed) mph (gusts \(day.wind.gust))", systemImage: "wind")
        } preview: {
            forecastPreview
        }
    }

    private var forecastAccessibilityLabel: String {
        var label = "\(day.dayOfWeek)"
        if isToday { label += ", today" }
        label += ". \(day.conditions). High \(day.high) degrees, low \(day.low) degrees."
        if day.snowfall > 0 {
            label += " \(day.snowfall) inches of snow expected."
        }
        label += " Wind \(day.wind.speed) miles per hour."
        return label
    }

    private var weatherIcon: String {
        let conditions = day.conditions.lowercased()
        if conditions.contains("snow") { return "cloud.snow.fill" }
        if conditions.contains("rain") { return "cloud.rain.fill" }
        if conditions.contains("cloud") { return "cloud.fill" }
        if conditions.contains("sun") || conditions.contains("clear") { return "sun.max.fill" }
        return "cloud.fill"
    }

    @ViewBuilder
    private var forecastPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(day.iconEmoji)
                    .font(.largeTitle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(day.dayOfWeek)
                        .font(.title2.bold())
                    Text(day.date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(day.high)°")
                        .font(.title.bold())
                    Text("\(day.low)°")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            Text(day.conditions)
                .font(.headline)

            HStack(spacing: 20) {
                if day.snowfall > 0 {
                    VStack(alignment: .leading) {
                        Text("Snowfall")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .foregroundColor(.blue)
                            Text("\(day.snowfall)\"")
                                .font(.title3.bold())
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Text("Wind")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(day.wind.speed) mph")
                        .font(.subheadline)
                }
            }

            if let mountainName = mountainName {
                Text(mountainName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

#Preview {
    VStack {
        ForecastDayRow(day: ForecastDay.mockWeek[0], isToday: true)
        Divider()
        ForecastDayRow(day: ForecastDay.mockWeek[1])
        Divider()
        ForecastDayRow(day: ForecastDay.mockWeek[2])
    }
    .padding()
}
