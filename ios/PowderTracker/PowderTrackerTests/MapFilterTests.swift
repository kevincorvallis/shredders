import XCTest
@testable import PowderTracker

final class MapFilterTests: XCTestCase {

    // MARK: - Test Data

    private func createTestMountain(
        id: String,
        name: String,
        shortName: String,
        region: String,
        passType: PassType? = nil
    ) -> Mountain {
        Mountain(
            id: id,
            name: name,
            shortName: shortName,
            region: region,
            color: "#3b82f6",
            elevation: Mountain.Elevation(base: 3500, summit: 5000),
            location: Mountain.Location(lat: 47.0, lng: -121.5),
            website: "https://example.com",
            snotel: nil,
            noaa: Mountain.NOAA(gridOffice: "SEW", gridX: 100, gridY: 100),
            webcams: [],
            passType: passType
        )
    }

    private var testMountains: [Mountain] {
        [
            createTestMountain(id: "baker", name: "Mt. Baker", shortName: "Baker", region: "washington", passType: nil),
            createTestMountain(id: "crystal", name: "Crystal Mountain", shortName: "Crystal", region: "washington", passType: .ikon),
            createTestMountain(id: "stevens", name: "Stevens Pass", shortName: "Stevens", region: "washington", passType: .epic),
            createTestMountain(id: "bachelor", name: "Mt. Bachelor", shortName: "Bachelor", region: "oregon", passType: .ikon),
            createTestMountain(id: "hood", name: "Mt. Hood Meadows", shortName: "Meadows", region: "oregon", passType: nil),
            createTestMountain(id: "schweitzer", name: "Schweitzer", shortName: "Schweitzer", region: "idaho", passType: .ikon)
        ]
    }

    // MARK: - SortOption Tests

    func testSortOption_AllCases_ShouldContainAllOptions() {
        XCTAssertEqual(SortOption.allCases.count, 4)
        XCTAssertTrue(SortOption.allCases.contains(.distance))
        XCTAssertTrue(SortOption.allCases.contains(.powderScore))
        XCTAssertTrue(SortOption.allCases.contains(.name))
        XCTAssertTrue(SortOption.allCases.contains(.favorites))
    }

    func testSortOption_RawValues_ShouldBeReadable() {
        XCTAssertEqual(SortOption.distance.rawValue, "Distance")
        XCTAssertEqual(SortOption.powderScore.rawValue, "Powder Score")
        XCTAssertEqual(SortOption.name.rawValue, "Name")
        XCTAssertEqual(SortOption.favorites.rawValue, "Favorites")
    }

    // MARK: - PassFilter Tests

    func testPassFilter_AllCases_ShouldContainAllFilters() {
        XCTAssertEqual(PassFilter.allCases.count, 6)
        XCTAssertTrue(PassFilter.allCases.contains(.all))
        XCTAssertTrue(PassFilter.allCases.contains(.epic))
        XCTAssertTrue(PassFilter.allCases.contains(.ikon))
        XCTAssertTrue(PassFilter.allCases.contains(.favorites))
        XCTAssertTrue(PassFilter.allCases.contains(.freshPowder))
        XCTAssertTrue(PassFilter.allCases.contains(.alertsActive))
    }

    func testPassFilter_Icons_ShouldNotBeEmpty() {
        for filter in PassFilter.allCases {
            XCTAssertFalse(filter.icon.isEmpty, "\(filter) icon should not be empty")
        }
    }

    func testPassFilter_PassTypeKey_ShouldMapCorrectly() {
        XCTAssertNil(PassFilter.all.passTypeKey)
        XCTAssertEqual(PassFilter.epic.passTypeKey, .epic)
        XCTAssertEqual(PassFilter.ikon.passTypeKey, .ikon)
        XCTAssertNil(PassFilter.favorites.passTypeKey)
        XCTAssertNil(PassFilter.freshPowder.passTypeKey)
        XCTAssertNil(PassFilter.alertsActive.passTypeKey)
    }

    // MARK: - Filter Logic Tests (Unit Tests for filtering algorithm)

    func testFilterBySearch_MatchingName_ShouldReturnResults() {
        // Given
        let mountains = testMountains
        let searchText = "Baker"

        // When
        let filtered = mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, "baker")
    }

    func testFilterBySearch_PartialMatch_ShouldReturnResults() {
        // Given
        let mountains = testMountains
        let searchText = "Mt."

        // When
        let filtered = mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }

        // Then
        XCTAssertEqual(filtered.count, 3) // Mt. Baker, Mt. Bachelor, Mt. Hood Meadows
    }

    func testFilterBySearch_CaseInsensitive_ShouldMatch() {
        // Given
        let mountains = testMountains
        let searchText = "CRYSTAL"

        // When
        let filtered = mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, "crystal")
    }

    func testFilterBySearch_NoMatch_ShouldReturnEmpty() {
        // Given
        let mountains = testMountains
        let searchText = "Nonexistent"

        // When
        let filtered = mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }

        // Then
        XCTAssertTrue(filtered.isEmpty)
    }

    func testFilterByRegion_ShouldReturnCorrectRegions() {
        // Given
        let mountains = testMountains

        // When
        let washington = mountains.filter { $0.region == "washington" }
        let oregon = mountains.filter { $0.region == "oregon" }
        let idaho = mountains.filter { $0.region == "idaho" }

        // Then
        XCTAssertEqual(washington.count, 3)
        XCTAssertEqual(oregon.count, 2)
        XCTAssertEqual(idaho.count, 1)
    }

    func testFilterByPassType_Epic_ShouldReturnEpicOnly() {
        // Given
        let mountains = testMountains

        // When
        let epicMountains = mountains.filter { $0.passType == .epic }

        // Then
        XCTAssertEqual(epicMountains.count, 1)
        XCTAssertEqual(epicMountains.first?.id, "stevens")
    }

    func testFilterByPassType_Ikon_ShouldReturnIkonOnly() {
        // Given
        let mountains = testMountains

        // When
        let ikonMountains = mountains.filter { $0.passType == .ikon }

        // Then
        XCTAssertEqual(ikonMountains.count, 3) // Crystal, Bachelor, Schweitzer
    }

    func testFilterByPassType_Independent_ShouldReturnNoPass() {
        // Given
        let mountains = testMountains

        // When
        let independentMountains = mountains.filter { $0.passType == nil }

        // Then
        XCTAssertEqual(independentMountains.count, 2) // Baker, Hood
    }

    // MARK: - Sort Logic Tests

    func testSortByName_ShouldSortAlphabetically() {
        // Given
        let mountains = testMountains

        // When
        let sorted = mountains.sorted { $0.name < $1.name }

        // Then
        XCTAssertEqual(sorted[0].id, "crystal") // Crystal Mountain
        XCTAssertEqual(sorted[1].id, "baker")   // Mt. Baker
        XCTAssertEqual(sorted[2].id, "bachelor") // Mt. Bachelor
    }

    func testSortByShortName_ShouldSortAlphabetically() {
        // Given
        let mountains = testMountains

        // When
        let sorted = mountains.sorted { $0.shortName < $1.shortName }

        // Then
        XCTAssertEqual(sorted[0].id, "bachelor") // Bachelor
        XCTAssertEqual(sorted[1].id, "baker")    // Baker
        XCTAssertEqual(sorted[2].id, "crystal")  // Crystal
    }

    // MARK: - Combined Filter Tests

    func testCombinedFilter_SearchAndPassType_ShouldApplyBoth() {
        // Given
        let mountains = testMountains
        let searchText = "Crystal"
        let passFilter: PassType = .ikon

        // When
        var filtered = mountains.filter { $0.passType == passFilter }
        filtered = filtered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, "crystal")
    }

    func testCombinedFilter_SearchAndRegion_ShouldApplyBoth() {
        // Given
        let mountains = testMountains
        let searchText = "Mt."
        let region = "oregon"

        // When
        var filtered = mountains.filter { $0.region == region }
        filtered = filtered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }

        // Then
        XCTAssertEqual(filtered.count, 2) // Mt. Bachelor, Mt. Hood Meadows
    }

    // MARK: - Edge Cases

    func testFilter_EmptySearchText_ShouldReturnAll() {
        // Given
        let mountains = testMountains
        let searchText = ""

        // When
        let filtered: [Mountain]
        if searchText.isEmpty {
            filtered = mountains
        } else {
            filtered = mountains.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Then
        XCTAssertEqual(filtered.count, testMountains.count)
    }

    func testFilter_WhitespaceSearch_ShouldReturnAll() {
        // Given
        let mountains = testMountains
        let searchText = "   "

        // When
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        let filtered: [Mountain]
        if trimmed.isEmpty {
            filtered = mountains
        } else {
            filtered = mountains.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed)
            }
        }

        // Then
        XCTAssertEqual(filtered.count, testMountains.count)
    }

    func testFilter_EmptyMountainList_ShouldReturnEmpty() {
        // Given
        let mountains: [Mountain] = []
        let searchText = "Baker"

        // When
        let filtered = mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }

        // Then
        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - Performance Tests

    func testFilterPerformance_LargeMountainList() {
        // Given - Create 1000 mountains
        var largeMountainList: [Mountain] = []
        for i in 0..<1000 {
            largeMountainList.append(createTestMountain(
                id: "mountain-\(i)",
                name: "Mountain \(i)",
                shortName: "M\(i)",
                region: ["washington", "oregon", "idaho"][i % 3],
                passType: i % 5 == 0 ? .ikon : (i % 7 == 0 ? .epic : nil)
            ))
        }

        // When/Then
        measure {
            let _ = largeMountainList
                .filter { $0.passType == .ikon }
                .filter { $0.name.localizedCaseInsensitiveContains("5") }
                .sorted { $0.name < $1.name }
        }
    }
}

// MARK: - PassType Tests

final class PassTypeTests: XCTestCase {

    func testPassType_AllCases() {
        XCTAssertTrue(PassType.allCases.contains(.epic))
        XCTAssertTrue(PassType.allCases.contains(.ikon))
        XCTAssertTrue(PassType.allCases.contains(.independent))
    }

    func testPassType_RawValues() {
        XCTAssertEqual(PassType.epic.rawValue, "epic")
        XCTAssertEqual(PassType.ikon.rawValue, "ikon")
        XCTAssertEqual(PassType.independent.rawValue, "independent")
    }
}
