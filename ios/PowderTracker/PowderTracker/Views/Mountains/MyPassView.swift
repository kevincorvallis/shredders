//
//  MyPassView.swift
//  PowderTracker
//
//  "What can I access with my pass?"
//  Focus: Pass filtering, value/savings
//
//  Extracted from MountainsTabView.swift for better code organization and
//  improved compilation performance.
//

import SwiftUI

struct MyPassView: View {
    @ObservedObject var viewModel: MountainSelectionViewModel
    var favoritesManager: FavoritesService
    @State private var selectedPass: PassSelection = .all

    enum PassSelection: String, CaseIterable {
        case all = "All"
        case epic = "Epic"
        case ikon = "Ikon"
        case independent = "Independent"

        var passType: PassType? {
            switch self {
            case .all: return nil
            case .epic: return .epic
            case .ikon: return .ikon
            case .independent: return .independent
            }
        }

        var color: Color {
            switch self {
            case .all: return .gray
            case .epic: return .purple
            case .ikon: return .orange
            case .independent: return .blue
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Pass selector
                passPicker
                    .padding(.horizontal)

                // Pass benefits summary (if specific pass selected)
                if selectedPass != .all {
                    passSummary
                        .padding(.horizontal)
                }

                // Mountains for selected pass
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(filteredMountains.count) Mountains")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(filteredMountains) { mountain in
                        NavigationLink {
                            MountainDetailView(mountain: mountain)
                        } label: {
                            PassMountainRow(
                                mountain: mountain,
                                conditions: viewModel.getConditions(for: mountain),
                                score: viewModel.getScore(for: mountain),
                                isFavorite: favoritesManager.isFavorite(mountain.id),
                                onFavoriteToggle: { toggleFavorite(mountain.id) }
                            )
                        }
                        .buttonStyle(.plain)
                        .navigationHaptic()
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 50)
            }
            .padding(.top)
        }
    }

    private var passPicker: some View {
        HStack(spacing: 8) {
            ForEach(PassSelection.allCases, id: \.self) { pass in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        selectedPass = pass
                    }
                } label: {
                    HStack(spacing: 6) {
                        if pass != .all {
                            Circle()
                                .fill(pass.color)
                                .frame(width: 8, height: 8)
                        }
                        Text(pass.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedPass == pass ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(selectedPass == pass ? pass.color : Color(.tertiarySystemBackground))
                    .cornerRadius(.cornerRadiusPill)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var passSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedPass.rawValue + " Pass")
                        .font(.headline)
                    Text("\(filteredMountains.count) mountains included")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Pass logo would go here
                Circle()
                    .fill(selectedPass.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(selectedPass.rawValue.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(selectedPass.color)
                    )
            }

            // Quick stats
            HStack(spacing: 16) {
                PassStat(value: "\(openOnPass)", label: "Open Now")
                PassStat(value: "\(freshOnPass)", label: "Fresh Snow")
                PassStat(value: bestScoreOnPass, label: "Best Score")
            }
        }
        .padding()
        .background(selectedPass.color.opacity(0.1))
        .cornerRadius(.cornerRadiusHero)
    }

    private var filteredMountains: [Mountain] {
        guard let passType = selectedPass.passType else {
            return viewModel.mountains.sorted {
                (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0)
            }
        }
        return viewModel.mountains
            .filter { $0.passType == passType }
            .sorted { (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0) }
    }

    private var openOnPass: Int {
        filteredMountains.filter {
            viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
        }.count
    }

    private var freshOnPass: Int {
        filteredMountains.filter {
            (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) >= 3
        }.count
    }

    private var bestScoreOnPass: String {
        let best = filteredMountains.compactMap { viewModel.getScore(for: $0) }.max() ?? 0
        return String(format: "%.1f", best)
    }

    private func toggleFavorite(_ id: String) {
        if favoritesManager.isFavorite(id) {
            favoritesManager.remove(id)
        } else {
            _ = favoritesManager.add(id)
        }
    }
}
