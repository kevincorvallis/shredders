import SwiftUI

struct SocialTab: View {
    var viewModel: LocationViewModel
    let mountain: Mountain

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                // Today's Activity
                todayActivityCard

                // Recent Check-ins
                recentCheckInsCard

                // Photo Grid Placeholder
                photoGridCard
            }
            .padding(.spacingM)
        }
    }

    // MARK: - Today's Activity

    private var todayActivityCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "figure.skiing.downhill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Today's Activity")
                    .font(.headline)
                Spacer()
            }

            Divider()

            HStack(spacing: .spacingXL) {
                activityStat(value: "247", label: "Skiers", trend: "+12%")
                activityStat(value: "23", label: "Check-ins", trend: "+8%")
                activityStat(value: "5", label: "Photos", trend: nil)
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func activityStat(value: String, label: String, trend: String?) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let trend = trend {
                Text(trend)
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recent Check-ins

    private var recentCheckInsCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Recent Check-ins")
                    .font(.headline)
                Spacer()
            }

            Divider()

            VStack(spacing: .spacingS) {
                checkInRow(name: "Sarah K.", time: "2h ago", message: "Fresh tracks on Chair 8! 🎿")
                checkInRow(name: "Mike T.", time: "3h ago", message: "Powder stashes in the trees")
                checkInRow(name: "Alex R.", time: "5h ago", message: "Lines are short today")
            }

            Button {
                // TODO: Show all check-ins
            } label: {
                Text("View All Check-ins")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func checkInRow(name: String, time: String, message: String) -> some View {
        HStack(alignment: .top, spacing: .spacingS) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(name.first ?? "?"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Photo Grid

    private var photoGridCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.pink)
                Text("Recent Photos")
                    .font(.headline)
                Spacer()
            }

            Divider()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundStyle(.quaternary)
                        }
                }
            }

            Button {
                // TODO: Show all photos
            } label: {
                Text("View All Photos")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}
