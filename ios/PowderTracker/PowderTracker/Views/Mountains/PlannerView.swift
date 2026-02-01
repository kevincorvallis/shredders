//
//  PlannerView.swift
//  PowderTracker
//
//  "Where should I go THIS WEEKEND?"
//  Focus: Forecast, comparison, trip planning
//
//  Extracted from MountainsTabView.swift for better code organization and
//  improved compilation performance.
//

import SwiftUI

struct PlannerView: View {
    @ObservedObject var viewModel: MountainSelectionViewModel
    var favoritesManager: FavoritesService
    @State private var selectedDay: PlanDay = .saturday
    @State private var compareList: [String] = []
    @State private var showComparison = false

    enum PlanDay: String, CaseIterable {
        case tomorrow = "Tomorrow"
        case saturday = "Saturday"
        case sunday = "Sunday"
        case nextWeek = "Next Week"
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Day picker
                dayPicker
                    .padding(.horizontal)

                // Comparison toolbar
                if !compareList.isEmpty {
                    comparisonToolbar
                        .padding(.horizontal)
                }

                // Best picks for selected day
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Best for \(selectedDay.rawValue)")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(bestForDay.prefix(5)) { mountain in
                                    PlannerCard(
                                        mountain: mountain,
                                        conditions: viewModel.getConditions(for: mountain),
                                        score: viewModel.getScore(for: mountain),
                                        isInCompareList: compareList.contains(mountain.id),
                                        onCompareToggle: { toggleCompare(mountain.id) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // All mountains with forecast
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Mountains")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.mountains) { mountain in
                            NavigationLink {
                                MountainDetailView(mountain: mountain)
                            } label: {
                                PlannerMountainRow(
                                    mountain: mountain,
                                    conditions: viewModel.getConditions(for: mountain),
                                    score: viewModel.getScore(for: mountain),
                                    isInCompareList: compareList.contains(mountain.id),
                                    onCompareToggle: { toggleCompare(mountain.id) }
                                )
                            }
                            .buttonStyle(.plain)
                            .navigationHaptic()
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer(minLength: 50)
            }
            .padding(.top)
        }
        .sheet(isPresented: $showComparison) {
            ComparisonSheet(
                mountains: compareList.compactMap { id in
                    viewModel.mountains.first { $0.id == id }
                },
                viewModel: viewModel
            )
            .modernSheetStyle()
        }
    }

    private var dayPicker: some View {
        HStack(spacing: 8) {
            ForEach(PlanDay.allCases, id: \.self) { day in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        selectedDay = day
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(dayLabel(day))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(dayNumber(day))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedDay == day ? Color.blue : Color(.tertiarySystemBackground))
                    .foregroundColor(selectedDay == day ? .white : .primary)
                    .cornerRadius(.cornerRadiusCard)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var comparisonToolbar: some View {
        HStack {
            Text("\(compareList.count) selected")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button("Clear") {
                withAnimation {
                    compareList.removeAll()
                }
            }
            .font(.subheadline)

            Button("Compare") {
                showComparison = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(compareList.count < 2)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private var bestForDay: [Mountain] {
        // TODO: Use actual forecast data for selected day
        viewModel.mountains.sorted {
            (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0)
        }
    }

    private func dayLabel(_ day: PlanDay) -> String {
        let calendar = Calendar.current
        let today = Date()

        switch day {
        case .tomorrow:
            return "TOM"
        case .saturday:
            let daysUntilSat = (7 - calendar.component(.weekday, from: today) + 7) % 7
            return daysUntilSat == 0 ? "TODAY" : "SAT"
        case .sunday:
            return "SUN"
        case .nextWeek:
            return "NEXT"
        }
    }

    private func dayNumber(_ day: PlanDay) -> String {
        let calendar = Calendar.current
        let today = Date()

        switch day {
        case .tomorrow:
            let date = calendar.date(byAdding: .day, value: 1, to: today)!
            return "\(calendar.component(.day, from: date))"
        case .saturday:
            let daysUntilSat = (7 - calendar.component(.weekday, from: today) + 7) % 7
            let date = calendar.date(byAdding: .day, value: daysUntilSat, to: today)!
            return "\(calendar.component(.day, from: date))"
        case .sunday:
            let daysUntilSun = (8 - calendar.component(.weekday, from: today)) % 7
            let date = calendar.date(byAdding: .day, value: daysUntilSun, to: today)!
            return "\(calendar.component(.day, from: date))"
        case .nextWeek:
            let date = calendar.date(byAdding: .day, value: 7, to: today)!
            return "\(calendar.component(.day, from: date))"
        }
    }

    private func toggleCompare(_ id: String) {
        if compareList.contains(id) {
            HapticFeedback.light.trigger()
            compareList.removeAll { $0 == id }
        } else if compareList.count < 4 {
            HapticFeedback.light.trigger()
            compareList.append(id)
        } else {
            // Max reached
            HapticFeedback.warning.trigger()
        }
    }
}
