import SwiftUI

// MARK: - Hourly Breakdown Sheet

struct HourlyBreakdownSheet: View {
    let mountain: Mountain
    let day: ForecastDay
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingL) {
                    // Day summary header
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text(day.dayOfWeek)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(day.date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Summary stats
                    HStack(spacing: .spacingL) {
                        statCard(
                            icon: "snowflake",
                            value: "\(day.snowfall)\"",
                            label: "Expected Snow"
                        )

                        statCard(
                            icon: "thermometer.medium",
                            value: "\(day.high)°/\(day.low)°",
                            label: "High/Low"
                        )

                        statCard(
                            icon: "wind",
                            value: "\(day.wind.speed)mph",
                            label: "Wind"
                        )
                    }
                    .padding(.horizontal)

                    // Conditions
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text("Conditions")
                            .font(.headline)

                        HStack(spacing: .spacingS) {
                            Text(day.iconEmoji)
                                .font(.title)

                            Text(day.conditions)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(.cornerRadiusCard)
                    }
                    .padding(.horizontal)

                    // Precipitation probability
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text("Precipitation")
                            .font(.headline)

                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                            Text("\(day.precipProbability)% chance of \(day.precipType)")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(.cornerRadiusCard)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle(mountain.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: .spacingXS) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}
