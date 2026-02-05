import SwiftUI

struct TabbedLocationView: View {
    let mountain: Mountain
    let initialTab: Tab?
    @State private var viewModel: LocationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab

    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case conditions = "Conditions"
        case travel = "Travel"
        case mountain = "Mountain"
        case social = "Social"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "gauge.with.dots.needle.bottom.50percent"
            case .conditions: return "cloud.sun.fill"
            case .travel: return "car.fill"
            case .mountain: return "mountain.2.fill"
            case .social: return "person.3.fill"
            }
        }

        var color: Color {
            switch self {
            case .overview: return .blue
            case .conditions: return .orange
            case .travel: return .green
            case .mountain: return .purple
            case .social: return .pink
            }
        }
    }

    init(mountain: Mountain, initialTab: Tab? = nil) {
        self.mountain = mountain
        self.initialTab = initialTab
        _viewModel = State(wrappedValue: LocationViewModel(mountain: mountain))
        _selectedTab = State(initialValue: initialTab ?? .overview)
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
            // Use skeleton loading for better perceived performance
            OverviewTabSkeleton()
                .padding(.top, 8)
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
            case .conditions:
                ConditionsTab(viewModel: viewModel, mountain: mountain)
            case .travel:
                TravelTab(viewModel: viewModel, mountain: mountain)
            case .mountain:
                MountainTab(viewModel: viewModel, mountain: mountain)
            case .social:
                SocialTab(viewModel: viewModel, mountain: mountain)
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
