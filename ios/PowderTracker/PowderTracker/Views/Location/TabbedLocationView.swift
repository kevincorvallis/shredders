import SwiftUI

struct TabbedLocationView: View {
    let mountain: Mountain
    @StateObject private var viewModel: LocationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .overview

    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case forecast = "Forecast"
        case history = "History"
        case travel = "Travel"
        case safety = "Safety"
        case webcams = "Webcams"
        case social = "Social"
        case lifts = "Lifts"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "gauge.with.dots.needle.bottom.50percent"
            case .forecast: return "cloud.sun.fill"
            case .history: return "chart.line.uptrend.xyaxis"
            case .travel: return "car.fill"
            case .safety: return "exclamationmark.triangle.fill"
            case .webcams: return "video.fill"
            case .social: return "person.3.fill"
            case .lifts: return "cablecar.fill"
            }
        }

        var color: Color {
            switch self {
            case .overview: return .blue
            case .forecast: return .orange
            case .history: return .purple
            case .travel: return .green
            case .safety: return .red
            case .webcams: return .cyan
            case .social: return .pink
            case .lifts: return .indigo
            }
        }
    }

    init(mountain: Mountain) {
        self.mountain = mountain
        _viewModel = StateObject(wrappedValue: LocationViewModel(mountain: mountain))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with mountain name
            header

            // Tab picker
            tabPicker
                .background(Color(.systemBackground))

            Divider()

            // Content
            ScrollView {
                tabContent
                    .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchData()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text(mountain.name)
                .font(.title2)
                .fontWeight(.bold)

            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Tab.allCases) { tab in
                    LocationTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        if viewModel.isLoading {
            ProgressView("Loading \(selectedTab.rawValue.lowercased())...")
                .frame(maxWidth: .infinity, minHeight: 300)
                .frame(alignment: .center)
        } else if let error = viewModel.error {
            ErrorView(message: error) {
                Task {
                    await viewModel.fetchData()
                }
            }
        } else {
            switch selectedTab {
            case .overview:
                OverviewTab(viewModel: viewModel, mountain: mountain, selectedTab: $selectedTab)
            case .forecast:
                ForecastTab(viewModel: viewModel, mountain: mountain)
            case .history:
                HistoryTab(viewModel: viewModel, mountain: mountain)
            case .travel:
                TravelTab(viewModel: viewModel, mountain: mountain)
            case .safety:
                SafetyTab(viewModel: viewModel, mountain: mountain)
            case .webcams:
                WebcamsTab(viewModel: viewModel, mountain: mountain)
            case .social:
                SocialTab(viewModel: viewModel, mountain: mountain)
            case .lifts:
                LiftsTab(viewModel: viewModel, mountain: mountain)
            }
        }
    }
}

// MARK: - Location Tab Button

struct LocationTabButton: View {
    let tab: TabbedLocationView.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                    .frame(width: 24, height: 24)

                Text(tab.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? tab.color : .secondary)
            .frame(width: 70)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        TabbedLocationView(mountain: Mountain.mock)
    }
}
