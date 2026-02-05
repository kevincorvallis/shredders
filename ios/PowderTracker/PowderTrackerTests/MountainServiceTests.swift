import XCTest
@testable import PowderTracker

/// Tests for MountainService - mountain data management
@MainActor
final class MountainServiceTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState_HasMockMountains() {
        let service = MountainService.shared

        XCTAssertFalse(service.allMountains.isEmpty,
                      "Should start with mock mountains before API fetch")
    }

    func testInitialState_IsNotLoading() {
        let service = MountainService.shared

        XCTAssertFalse(service.isLoading,
                      "Should not be loading initially")
    }

    func testInitialState_NoError() {
        let service = MountainService.shared

        XCTAssertNil(service.error,
                    "Should have no error initially")
    }

    // MARK: - Mountain Lookup

    func testMountainById_FindsExistingMountain() {
        let service = MountainService.shared

        // Mock mountains should include common ones
        guard let firstMountain = service.allMountains.first else {
            XCTFail("Should have at least one mountain")
            return
        }

        let found = service.mountain(byId: firstMountain.id)
        XCTAssertNotNil(found, "Should find mountain by ID")
        XCTAssertEqual(found?.id, firstMountain.id)
        XCTAssertEqual(found?.name, firstMountain.name)
    }

    func testMountainById_ReturnsNilForUnknownId() {
        let service = MountainService.shared

        let found = service.mountain(byId: "nonexistent-mountain-id-12345")
        XCTAssertNil(found, "Should return nil for unknown mountain ID")
    }

    func testMountainById_EmptyString() {
        let service = MountainService.shared

        let found = service.mountain(byId: "")
        XCTAssertNil(found, "Should return nil for empty ID")
    }

    // MARK: - Mock Mountains Validity

    func testMockMountains_HaveRequiredFields() {
        let mountains = Mountain.mockMountains

        for mountain in mountains {
            XCTAssertFalse(mountain.id.isEmpty, "Mountain ID should not be empty: \(mountain.name)")
            XCTAssertFalse(mountain.name.isEmpty, "Mountain name should not be empty: \(mountain.id)")
            XCTAssertFalse(mountain.shortName.isEmpty, "Short name should not be empty: \(mountain.id)")
            XCTAssertFalse(mountain.region.isEmpty, "Region should not be empty: \(mountain.id)")
        }
    }

    func testMockMountains_HaveValidRegions() {
        let mountains = Mountain.mockMountains
        let validRegions = ["washington", "oregon", "idaho"]

        for mountain in mountains {
            XCTAssertTrue(validRegions.contains(mountain.region),
                         "Mountain \(mountain.id) has unexpected region: \(mountain.region)")
        }
    }

    func testMockMountains_HaveValidElevations() {
        let mountains = Mountain.mockMountains

        for mountain in mountains {
            XCTAssertGreaterThan(mountain.elevation.summit, mountain.elevation.base,
                               "Summit should be higher than base for \(mountain.id)")
            XCTAssertGreaterThan(mountain.elevation.base, 0,
                               "Base elevation should be positive for \(mountain.id)")
        }
    }

    // MARK: - Mountain Mock Factory

    func testMockFactory_CreatesValidMountain() {
        let mountain = Mountain.mock(
            id: "test-mountain",
            name: "Test Mountain",
            shortName: "Test",
            region: "washington"
        )

        XCTAssertEqual(mountain.id, "test-mountain")
        XCTAssertEqual(mountain.name, "Test Mountain")
        XCTAssertEqual(mountain.shortName, "Test")
        XCTAssertEqual(mountain.region, "washington")
    }

    func testMockFactory_EpicPass() {
        let mountain = Mountain.mockEpicPass()

        XCTAssertEqual(mountain.passType, .epic)
    }

    func testMockFactory_IkonPass() {
        let mountain = Mountain.mockIkonPass()

        XCTAssertEqual(mountain.passType, .ikon)
    }

    func testMockFactory_Independent() {
        let mountain = Mountain.mockIndependent()

        XCTAssertEqual(mountain.passType, .independent)
    }

    func testMockFactory_List() {
        let mountains = Mountain.mockList(count: 10)

        XCTAssertEqual(mountains.count, 10)
        // Verify unique IDs
        let ids = Set(mountains.map { $0.id })
        XCTAssertEqual(ids.count, 10, "All mock mountains should have unique IDs")
    }
}
