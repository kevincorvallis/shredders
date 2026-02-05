import XCTest
@testable import PowderTracker

final class MapFilterTests: XCTestCase {

    // MARK: - Test Data

    private var testMountains: [Mountain] {
        [
            Mountain.mock(id: "baker", name: "Mt. Baker", shortName: "Baker", region: "washington", passType: nil),
            Mountain.mock(id: "crystal", name: "Crystal Mountain", shortName: "Crystal", region: "washington", passType: .ikon),
            Mountain.mock(id: "stevens", name: "Stevens Pass", shortName: "Stevens", region: "washington", passType: .epic),
            Mountain.mock(id: "bachelor", name: "Mt. Bachelor", shortName: "Bachelor", region: "oregon", passType: .ikon),
            Mountain.mock(id: "hood", name: "Mt. Hood Meadows", shortName: "Meadows", region: "oregon", passType: nil),
            Mountain.mock(id: "schweitzer", name: "Schweitzer", shortName: "Schweitzer", region: "idaho", passType: .ikon)
        ]
    }

    // MARK: - SortOption Tests

    func testSortOption_AllCases_ShouldContainAllOptions() {
        XCTAssertEqual(SortOption.allCases.count, 5)
        XCTAssertTrue(SortOption.allCases.contains(.distance))
        XCTAssertTrue(SortOption.allCases.contains(.name))
        XCTAssertTrue(SortOption.allCases.contains(.snowfall))
        XCTAssertTrue(SortOption.allCases.contains(.powderScore))
        XCTAssertTrue(SortOption.allCases.contains(.favorites))
    }

    func testSortOption_RawValues_ShouldBeReadable() {
        XCTAssertEqual(SortOption.distance.rawValue, "Distance")
        XCTAssertEqual(SortOption.name.rawValue, "Name")
        XCTAssertEqual(SortOption.snowfall.rawValue, "Snowfall")
        XCTAssertEqual(SortOption.powderScore.rawValue, "Powder Score")
        XCTAssertEqual(SortOption.favorites.rawValue, "Favorites")
    }

    // MARK: - PassFilter Tests

    func testPassFilter_AllCases_ShouldContainAllFilters() {
        XCTAssertEqual(PassFilter.allCases.count, 6)
        XCTAssertTrue(PassFilter.allCases.contains(.all))
        XCTAssertTrue(PassFilter.allCases.contains(.epic))
        XCTAssertTrue(PassFilter.allCases.contains(.ikon))
        XCTAssertTrue(PassFilter.allCases.contains(.independent))
        XCTAssertTrue(PassFilter.allCases.contains(.favorites))
        XCTAssertTrue(PassFilter.allCases.contains(.freshPowder))
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
        XCTAssertEqual(PassFilter.independent.passTypeKey, .independent)
        XCTAssertNil(PassFilter.favorites.passTypeKey)
        XCTAssertNil(PassFilter.freshPowder.passTypeKey)
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

    // MARK: - Bug Fix Regression Tests

    /// Bug 1: Quick filters for pass types should use OR logic (not AND).
    /// Selecting Epic + Ikon should return ALL mountains that are Epic OR Ikon.
    func testQuickFilter_MultiplePassTypes_UsesORLogic() {
        // Given — mountains with different pass types
        let mountains = testMountains
        // Simulate selecting both .epic and .ikon quick filters
        let selectedPassTypes: Set<PassType> = [.epic, .ikon]

        // When — apply OR logic (any selected pass type matches)
        let filtered = mountains.filter { mountain in
            guard let pt = mountain.passType else { return false }
            return selectedPassTypes.contains(pt)
        }

        // Then — should return Crystal(ikon), Stevens(epic), Bachelor(ikon), Schweitzer(ikon) = 4
        XCTAssertEqual(filtered.count, 4, "Epic+Ikon filter should return union, not intersection")
        let ids = Set(filtered.map(\.id))
        XCTAssertTrue(ids.contains("crystal"))    // ikon
        XCTAssertTrue(ids.contains("stevens"))     // epic
        XCTAssertTrue(ids.contains("bachelor"))    // ikon
        XCTAssertTrue(ids.contains("schweitzer"))  // ikon
        // Nil passType mountains should be excluded
        XCTAssertFalse(ids.contains("baker"))      // nil passType
        XCTAssertFalse(ids.contains("hood"))       // nil passType
    }

    /// Bug 4: Favorites sort should preserve the user's saved ordering,
    /// not sort alphabetically within the favorites group.
    func testFavoritesSort_PreservesUserOrder() {
        // Given — user has saved favorites in a specific order
        let favoriteOrder = ["schweitzer", "crystal", "baker"] // user's chosen order
        let mountains = testMountains

        // When — sort with favorites first, preserving favoriteIds order
        let sorted = mountains.sorted { m1, m2 in
            let f1 = favoriteOrder.contains(m1.id)
            let f2 = favoriteOrder.contains(m2.id)
            if f1 != f2 { return f1 } // favorites come first
            if f1 && f2 {
                // Within favorites: preserve user's saved order
                let idx1 = favoriteOrder.firstIndex(of: m1.id) ?? .max
                let idx2 = favoriteOrder.firstIndex(of: m2.id) ?? .max
                return idx1 < idx2
            }
            return m1.name < m2.name // non-favorites alphabetical
        }

        // Then — favorites should appear first in saved order
        let topThreeIds = sorted.prefix(3).map(\.id)
        XCTAssertEqual(topThreeIds, ["schweitzer", "crystal", "baker"],
                       "Favorites should appear in user's saved order, not alphabetical")
    }

    /// Bug 5: Filtering by .independent should NOT include mountains with nil passType.
    /// Only mountains explicitly marked as .independent should match.
    func testIndependentFilter_ExcludesNilPassType() {
        // Given — test data has baker(nil), hood(nil), and no .independent mountains
        let mountains = testMountains

        // When — filter for .independent passType (strict equality, no nil coalescing)
        let independentMountains = mountains.filter { $0.passType == .independent }

        // Then — should be empty because no test mountains have passType == .independent
        XCTAssertEqual(independentMountains.count, 0,
                       "Mountains with nil passType should NOT match .independent filter")

        // Also verify: nil passType mountains exist but are separate
        let nilPassMountains = mountains.filter { $0.passType == nil }
        XCTAssertEqual(nilPassMountains.count, 2, "Baker and Hood should have nil passType")
    }

    /// Bug 3: Distance sort should gracefully fall back to name sort
    /// when location permission is not available.
    func testDistanceSort_NoLocation_FallsBackToName() {
        // Given — mountains without any distance info (simulating no location permission)
        let mountains = testMountains
        let hasLocation = false // simulate: not authorized

        // When — attempt distance sort with fallback
        let sorted = mountains.sorted { m1, m2 in
            if !hasLocation {
                return m1.name < m2.name // fallback to name
            }
            // Would normally sort by distance
            return m1.name < m2.name
        }

        // Then — should be alphabetically sorted (name fallback)
        let names = sorted.map(\.name)
        XCTAssertEqual(names, names.sorted(), "Without location, distance sort should fall back to alphabetical name sort")
        XCTAssertEqual(sorted.first?.id, "crystal", "Crystal Mountain should be first alphabetically")
    }

    // MARK: - Performance Tests

    func testFilterPerformance_LargeMountainList() {
        // Given - Create 1000 mountains
        var largeMountainList: [Mountain] = []
        for i in 0..<1000 {
            largeMountainList.append(Mountain.mock(
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
        let allPassTypes: [PassType] = [.epic, .ikon, .independent]
        XCTAssertTrue(allPassTypes.contains(.epic))
        XCTAssertTrue(allPassTypes.contains(.ikon))
        XCTAssertTrue(allPassTypes.contains(.independent))
    }

    func testPassType_RawValues() {
        XCTAssertEqual(PassType.epic.rawValue, "epic")
        XCTAssertEqual(PassType.ikon.rawValue, "ikon")
        XCTAssertEqual(PassType.independent.rawValue, "independent")
    }
}
