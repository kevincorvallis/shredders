import SwiftUI

struct ForecastDayRow: View {
    let day: ForecastDay
    var isToday: Bool = false

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
