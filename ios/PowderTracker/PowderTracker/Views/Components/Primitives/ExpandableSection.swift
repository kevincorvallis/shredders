import SwiftUI

/// A reusable expandable section component with toggle button
/// Consolidates expandable logic from: AtAGlanceCard, ArrivalTimeCard, ParkingCard, LiftLinePredictorCard
struct ExpandableSection<Content: View>: View {
    let title: String
    let icon: String
    let count: Int?
    let color: Color
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: .spacingM) {
            // Toggle button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(.subheadline)

                    Text(titleWithCount)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundColor(color)
                .padding(.spacingM)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadiusCard)
                        .fill(color.opacity(.opacitySubtle))
                )
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: .spacingS) {
                    content()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Helpers

    private var titleWithCount: String {
        if let count = count {
            return "\(title) (\(count))"
        }
        return title
    }
}

// MARK: - Preview

#Preview("Expandable Sections") {
    struct PreviewWrapper: View {
        @State private var showLots = false
        @State private var showTips = false
        @State private var showAlternatives = false

        var body: some View {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // Parking Lots Section
                    ExpandableSection(
                        title: "Parking Lots",
                        icon: "parkingsign.circle.fill",
                        count: 3,
                        color: .blue,
                        isExpanded: $showLots
                    ) {
                        ForEach(0..<3) { index in
                            Text("Parking Lot \(index + 1)")
                                .font(.subheadline)
                                .padding(.spacingM)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(.cornerRadiusButton)
                        }
                    }

                    // Tips Section
                    ExpandableSection(
                        title: "Pro Tips",
                        icon: "lightbulb.fill",
                        count: 5,
                        color: .orange,
                        isExpanded: $showTips
                    ) {
                        ForEach(0..<5) { index in
                            HStack(alignment: .top, spacing: .spacingS) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)

                                Text("Tip \(index + 1): This is a helpful tip for users")
                                    .font(.subheadline)
                            }
                        }
                    }

                    // Alternative Times Section
                    ExpandableSection(
                        title: "Alternative Times",
                        icon: "arrow.triangle.2.circlepath",
                        count: nil,
                        color: .blue,
                        isExpanded: $showAlternatives
                    ) {
                        ForEach(0..<3) { index in
                            VStack(alignment: .leading, spacing: .spacingXS) {
                                Text("Alternative \(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text("Description of this alternative option")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.spacingM)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(.cornerRadiusButton)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
