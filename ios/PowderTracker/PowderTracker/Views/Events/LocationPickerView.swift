//
//  LocationPickerView.swift
//  PowderTracker
//
//  A view for searching and selecting meeting point locations using Apple Maps
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchService = LocationSearchService()

    @Binding var selectedLocation: String

    // Track initial value to support cancel
    @State private var initialLocation: String = ""
    @State private var showManualEntry: Bool = false
    @State private var manualEntryText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selected location preview
                if let address = searchService.selectedAddress {
                    selectedLocationSection(address: address)
                }

                // Content
                if searchService.searchQuery.isEmpty && searchService.selectedAddress == nil {
                    emptyStateView
                } else if searchService.isSearching {
                    loadingView
                } else if searchService.searchResults.isEmpty && !searchService.searchQuery.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }

                Spacer()

                // Manual entry option
                manualEntryButton
            }
            .navigationTitle("Meeting Point")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchService.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search for a place..."
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        selectedLocation = initialLocation
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let address = searchService.selectedAddress {
                            selectedLocation = address
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(searchService.selectedAddress == nil && selectedLocation.isEmpty)
                }
            }
            .sheet(isPresented: $showManualEntry) {
                manualEntrySheet
            }
            .onAppear {
                initialLocation = selectedLocation
                if !selectedLocation.isEmpty {
                    searchService.selectedAddress = selectedLocation
                }
            }
        }
    }

    // MARK: - Selected Location Section

    @ViewBuilder
    private func selectedLocationSection(address: String) -> some View {
        VStack(spacing: 12) {
            // Map preview if we have coordinates
            if let coordinate = searchService.selectedCoordinate {
                MiniLocationMapView(coordinate: coordinate, title: address)
                    .frame(height: 120)
                    .padding(.horizontal)
            }

            // Address display
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Text(address)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer()

                Button {
                    searchService.clearSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
        }
        .padding(.top, 8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Search for a location")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Type an address, business name, or landmark to find a meeting point.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No results found")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Try a different search or enter the address manually.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        List {
            ForEach(searchService.searchResults, id: \.self) { completion in
                LocationSearchResultRow(completion: completion)
                    .onTapGesture {
                        HapticFeedback.selection.trigger()
                        Task {
                            await searchService.selectCompletion(completion)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Manual Entry Button

    private var manualEntryButton: some View {
        Button {
            manualEntryText = selectedLocation
            showManualEntry = true
        } label: {
            HStack {
                Image(systemName: "pencil")
                Text("Enter address manually")
            }
            .font(.subheadline)
            .foregroundStyle(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Manual Entry Sheet

    private var manualEntrySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Meeting point address", text: $manualEntryText, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Address")
                } footer: {
                    Text("Enter the full address or a description of the meeting location.")
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showManualEntry = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmed = manualEntryText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            searchService.selectedAddress = trimmed
                            searchService.selectedCoordinate = nil
                        }
                        showManualEntry = false
                    }
                    .fontWeight(.semibold)
                    .disabled(manualEntryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    @Previewable @State var location = ""
    LocationPickerView(selectedLocation: $location)
}
