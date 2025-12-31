import SwiftUI
import Charts

/// Horizontal scrollable snow timeline showing past and future snowfall (OpenSnow-style)
struct SnowTimelineView: View {
    let snowData: [SnowDataPoint]
    let liftStatus: LiftStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with lift status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snow Forecast")
                        .font(.title3)
                        .fontWeight(.bold)

                    if let status = liftStatus {
                        HStack(spacing: 8) {
                            StatusDot(isOpen: status.isOpen)
                            Text(status.isOpen ? "Open" : "Closed")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(status.isOpen ? .green : .red)

                            if status.percentOpen > 0 {
                                Text("\(status.percentOpen)% open")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                // Total snow summary
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(totalPastSnow)\"")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Image(systemName: "arrow.left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Past 7d")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(totalFutureSnow)\"")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    Text("Next 7d")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Horizontal scrollable timeline
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(snowData) { dataPoint in
                            SnowDayBar(dataPoint: dataPoint, maxSnow: maxSnowValue)
                                .id(dataPoint.id)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 180)
                .onAppear {
                    // Scroll to today on appear
                    if let todayIndex = snowData.firstIndex(where: { $0.isToday }) {
                        proxy.scrollTo(snowData[todayIndex].id, anchor: .center)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var totalPastSnow: Int {
        snowData.filter { !$0.isForecast && !$0.isToday }.reduce(0) { $0 + $1.snowfall }
    }

    private var totalFutureSnow: Int {
        snowData.filter { $0.isForecast }.reduce(0) { $0 + $1.snowfall }
    }

    private var maxSnowValue: Int {
        snowData.map { $0.snowfall }.max() ?? 10
    }
}

// MARK: - Snow Day Bar

struct SnowDayBar: View {
    let dataPoint: SnowDataPoint
    let maxSnow: Int

    var body: some View {
        VStack(spacing: 6) {
            // Snow amount text
            if dataPoint.snowfall > 0 {
                Text("\(dataPoint.snowfall)\"")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(barColor)
            } else {
                Text("-")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
            }

            // Bar chart
            VStack {
                Spacer()

                Rectangle()
                    .fill(barColor.opacity(dataPoint.isForecast ? 0.6 : 1.0))
                    .frame(width: 32, height: barHeight)
                    .cornerRadius(4, corners: [.topLeft, .topRight])
            }
            .frame(height: 100)

            // Date label
            VStack(spacing: 2) {
                Text(dataPoint.dayOfWeek)
                    .font(.caption2)
                    .fontWeight(dataPoint.isToday ? .bold : .regular)
                    .foregroundColor(dataPoint.isToday ? .primary : .secondary)

                Text(dataPoint.dateLabel)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // "Today" indicator
            if dataPoint.isToday {
                Text("TODAY")
                    .font(.system(size: 8))
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .frame(width: 44)
        .background(dataPoint.isToday ? Color.blue.opacity(0.05) : Color.clear)
        .cornerRadius(8)
    }

    private var barHeight: CGFloat {
        let minHeight: CGFloat = 8
        let maxHeight: CGFloat = 100

        guard maxSnow > 0, dataPoint.snowfall > 0 else { return minHeight }

        let ratio = Double(dataPoint.snowfall) / Double(maxSnow)
        return minHeight + (maxHeight - minHeight) * ratio
    }

    private var barColor: Color {
        if dataPoint.isForecast {
            return .purple
        } else if dataPoint.isToday {
            return .blue
        } else {
            return .blue
        }
    }
}

// MARK: - Status Dot

struct StatusDot: View {
    let isOpen: Bool

    var body: some View {
        Circle()
            .fill(isOpen ? Color.green : Color.red)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Helper Extension for Rounded Corners

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    let mockData = generateMockSnowData()
    let mockStatus = LiftStatus(
        isOpen: true,
        liftsOpen: 32,
        liftsTotal: 37,
        runsOpen: 175,
        runsTotal: 200,
        message: "Great conditions!",
        lastUpdated: Date().ISO8601Format()
    )

    return SnowTimelineView(snowData: mockData, liftStatus: mockStatus)
        .padding()
        .background(Color(.systemGroupedBackground))
}

private func generateMockSnowData() -> [SnowDataPoint] {
    var data: [SnowDataPoint] = []
    let today = Date()

    // Past 7 days
    for i in (1...7).reversed() {
        let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
        data.append(SnowDataPoint(
            date: date,
            snowfall: [0, 2, 5, 8, 12, 3, 0].randomElement()!,
            isForecast: false,
            isToday: false
        ))
    }

    // Today
    data.append(SnowDataPoint(
        date: today,
        snowfall: 6,
        isForecast: false,
        isToday: true
    ))

    // Next 7 days
    for i in 1...7 {
        let date = Calendar.current.date(byAdding: .day, value: i, to: today)!
        data.append(SnowDataPoint(
            date: date,
            snowfall: [0, 1, 3, 7, 10, 4, 2].randomElement()!,
            isForecast: true,
            isToday: false
        ))
    }

    return data
}
