import SwiftUI
import Charts

struct SnowDepthChart: View {
    let history: [HistoryDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Snow Depth (30 Days)")
                .font(.headline)

            Chart(history) { point in
                LineMark(
                    x: .value("Date", point.formattedDate ?? Date()),
                    y: .value("Depth", point.snowDepth)
                )
                .foregroundStyle(Color.blue.gradient)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", point.formattedDate ?? Date()),
                    y: .value("Depth", point.snowDepth)
                )
                .foregroundStyle(Color.blue.opacity(0.1).gradient)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let depth = value.as(Int.self) {
                            Text("\(depth)\"")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    SnowDepthChart(history: HistoryDataPoint.mockHistory())
        .padding()
        .background(Color(.systemGroupedBackground))
}
