//
//  LocationSearchService.swift
//  PowderTracker
//
//  Service for searching locations using Apple Maps
//

import Foundation
import MapKit
import Combine

@MainActor
@Observable
class LocationSearchService: NSObject {
    // MARK: - Published Properties

    var searchQuery: String = "" {
        didSet {
            searchQuerySubject.send(searchQuery)
        }
    }
    var searchResults: [MKLocalSearchCompletion] = []
    var isSearching: Bool = false
    var error: Error?

    // Selected location data
    var selectedCoordinate: CLLocationCoordinate2D?
    var selectedAddress: String?

    // MARK: - Private Properties

    private var searchCompleter: MKLocalSearchCompleter
    private var cancellables = Set<AnyCancellable>()
    private let searchQuerySubject = PassthroughSubject<String, Never>()

    // MARK: - Initialization

    override init() {
        searchCompleter = MKLocalSearchCompleter()
        super.init()

        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]

        // Bias results toward Pacific Northwest region
        let pnwCenter = CLLocationCoordinate2D(latitude: 47.5, longitude: -121.5)
        let pnwRegion = MKCoordinateRegion(
            center: pnwCenter,
            latitudinalMeters: 800_000,
            longitudinalMeters: 800_000
        )
        searchCompleter.region = pnwRegion

        // Debounce search queries
        searchQuerySubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    // MARK: - Search Methods

    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchCompleter.queryFragment = query
    }

    /// Select a completion and get full address details
    func selectCompletion(_ completion: MKLocalSearchCompletion) async {
        isSearching = true
        error = nil

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            guard let mapItem = response.mapItems.first else {
                // Fall back to completion text
                selectedAddress = formatCompletionAsAddress(completion)
                selectedCoordinate = nil
                isSearching = false
                return
            }

            selectedAddress = formatAddress(from: mapItem)
            selectedCoordinate = mapItem.placemark.coordinate
        } catch {
            self.error = error
            // Fall back to completion text
            selectedAddress = formatCompletionAsAddress(completion)
            selectedCoordinate = nil
        }

        isSearching = false
    }

    /// Clear the current selection
    func clearSelection() {
        selectedAddress = nil
        selectedCoordinate = nil
        searchQuery = ""
        searchResults = []
    }

    // MARK: - Address Formatting

    private func formatAddress(from mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark

        var components: [String] = []

        // Add name if it's a point of interest
        if let name = mapItem.name,
           name != placemark.name,
           !name.isEmpty {
            components.append(name)
        }

        // Street address
        if let streetNumber = placemark.subThoroughfare,
           let street = placemark.thoroughfare {
            components.append("\(streetNumber) \(street)")
        } else if let street = placemark.thoroughfare {
            components.append(street)
        }

        // City, State
        var cityState: [String] = []
        if let city = placemark.locality {
            cityState.append(city)
        }
        if let state = placemark.administrativeArea {
            cityState.append(state)
        }
        if !cityState.isEmpty {
            components.append(cityState.joined(separator: ", "))
        }

        return components.joined(separator: ", ")
    }

    private func formatCompletionAsAddress(_ completion: MKLocalSearchCompletion) -> String {
        if completion.subtitle.isEmpty {
            return completion.title
        }
        return "\(completion.title), \(completion.subtitle)"
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Wrap results to satisfy Swift's concurrency checking
        // This is safe because we're dispatching to the main queue
        let wrapper = UncheckedSendableWrapper(completer.results)
        DispatchQueue.main.async { [weak self] in
            self?.searchResults = wrapper.value
            self?.isSearching = false
            self?.error = nil
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        let wrapper = UncheckedSendableWrapper(error)
        DispatchQueue.main.async { [weak self] in
            // Don't show error for cancelled searches
            if (wrapper.value as NSError).code != MKError.Code.placemarkNotFound.rawValue {
                self?.error = wrapper.value
            }
            self?.isSearching = false
        }
    }
}

// Helper to satisfy Swift's Sendable requirements
// Safe for main queue dispatch patterns
private struct UncheckedSendableWrapper<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}
