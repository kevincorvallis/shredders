import XCTest
@testable import PowderTracker

/// Tests for FavoritesService - favorite mountains management
@MainActor
final class FavoritesServiceTests: XCTestCase {

    private var service: FavoritesService!
    private let testStorageKey = "favoriteMountainIds"

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: testStorageKey)
        UserDefaults.standard.removeObject(forKey: "selectedMountainId")
        service = FavoritesService()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testStorageKey)
        UserDefaults.standard.removeObject(forKey: "selectedMountainId")
        service = nil
        super.tearDown()
    }

    // MARK: - Default Favorites

    func testDefaultFavorites_AreSet() {
        // When initialized with no prior data, defaults should be set
        XCTAssertFalse(service.favoriteIds.isEmpty,
                      "Should have default favorites on first launch")
    }

    func testDefaultFavorites_ContainExpectedMountains() {
        let defaults = FavoritesService.defaultFavorites
        XCTAssertEqual(defaults, ["baker", "crystal", "stevens"],
                      "Default favorites should be Baker, Crystal, and Stevens")
    }

    // MARK: - Add Favorite

    func testAdd_SucceedsUnderLimit() {
        service.favoriteIds = []

        let result = service.add("test-mountain")

        XCTAssertTrue(result, "Should successfully add a favorite")
        XCTAssertTrue(service.favoriteIds.contains("test-mountain"))
    }

    func testAdd_FailsAtMaxLimit() {
        // Fill to max (5)
        service.favoriteIds = ["m1", "m2", "m3", "m4", "m5"]

        let result = service.add("m6")

        XCTAssertFalse(result, "Should fail to add when at max favorites")
        XCTAssertFalse(service.favoriteIds.contains("m6"))
        XCTAssertEqual(service.favoriteIds.count, 5)
    }

    func testAdd_DuplicateReturnsTrueWithoutDuplicating() {
        service.favoriteIds = ["existing-mountain"]

        let result = service.add("existing-mountain")

        XCTAssertTrue(result, "Adding existing favorite should return true")
        XCTAssertEqual(service.favoriteIds.filter { $0 == "existing-mountain" }.count, 1,
                      "Should not duplicate the favorite")
    }

    // MARK: - Remove Favorite

    func testRemove_ExistingFavorite() {
        service.favoriteIds = ["m1", "m2", "m3"]

        service.remove("m2")

        XCTAssertFalse(service.favoriteIds.contains("m2"))
        XCTAssertEqual(service.favoriteIds.count, 2)
    }

    func testRemove_NonExistentFavorite_DoesNothing() {
        service.favoriteIds = ["m1", "m2"]
        let countBefore = service.favoriteIds.count

        service.remove("nonexistent")

        XCTAssertEqual(service.favoriteIds.count, countBefore)
    }

    // MARK: - Toggle Favorite

    func testToggleFavorite_AddWhenNotPresent() {
        service.favoriteIds = []

        let result = service.toggleFavorite("new-mountain")

        XCTAssertTrue(result, "Toggle should return true when adding")
        XCTAssertTrue(service.isFavorite("new-mountain"))
    }

    func testToggleFavorite_RemoveWhenPresent() {
        service.favoriteIds = ["existing"]

        let result = service.toggleFavorite("existing")

        XCTAssertFalse(result, "Toggle should return false when removing")
        XCTAssertFalse(service.isFavorite("existing"))
    }

    // MARK: - isFavorite

    func testIsFavorite_ReturnsTrueForFavorited() {
        service.favoriteIds = ["baker", "crystal"]

        XCTAssertTrue(service.isFavorite("baker"))
        XCTAssertTrue(service.isFavorite("crystal"))
    }

    func testIsFavorite_ReturnsFalseForNonFavorited() {
        service.favoriteIds = ["baker"]

        XCTAssertFalse(service.isFavorite("stevens"))
    }

    // MARK: - Capacity

    func testCanAddMore_TrueWhenUnderLimit() {
        service.favoriteIds = ["m1", "m2"]

        XCTAssertTrue(service.canAddMore())
    }

    func testCanAddMore_FalseWhenAtLimit() {
        service.favoriteIds = ["m1", "m2", "m3", "m4", "m5"]

        XCTAssertFalse(service.canAddMore())
    }

    func testRemainingSlots_CalculatesCorrectly() {
        service.favoriteIds = ["m1", "m2"]

        XCTAssertEqual(service.remainingSlots(), 3)
    }

    func testRemainingSlots_ZeroAtMax() {
        service.favoriteIds = ["m1", "m2", "m3", "m4", "m5"]

        XCTAssertEqual(service.remainingSlots(), 0)
    }

    func testRemainingSlots_FiveWhenEmpty() {
        service.favoriteIds = []

        XCTAssertEqual(service.remainingSlots(), 5)
    }

    // MARK: - Reorder

    func testReorder_MoveFromFirstToLast() {
        service.favoriteIds = ["a", "b", "c"]

        service.reorder(from: IndexSet(integer: 0), to: 3)

        XCTAssertEqual(service.favoriteIds, ["b", "c", "a"])
    }

    func testReorder_MoveFromLastToFirst() {
        service.favoriteIds = ["a", "b", "c"]

        service.reorder(from: IndexSet(integer: 2), to: 0)

        XCTAssertEqual(service.favoriteIds, ["c", "a", "b"])
    }

    // MARK: - Persistence

    func testPersistence_SavesAndLoads() {
        // Set favorites
        service.favoriteIds = []
        _ = service.add("persist-test-1")
        _ = service.add("persist-test-2")

        // Create new instance to test loading
        let newService = FavoritesService()

        XCTAssertTrue(newService.favoriteIds.contains("persist-test-1"),
                     "Should persist and reload favorites")
        XCTAssertTrue(newService.favoriteIds.contains("persist-test-2"),
                     "Should persist and reload favorites")
    }

    func testPersistence_EnforcesMaxOnLoad() {
        // Manually write more than max favorites to UserDefaults
        let tooMany = ["m1", "m2", "m3", "m4", "m5", "m6", "m7"]
        if let data = try? JSONEncoder().encode(tooMany) {
            UserDefaults.standard.set(data, forKey: testStorageKey)
        }

        let newService = FavoritesService()

        XCTAssertLessThanOrEqual(newService.favoriteIds.count, 5,
                                "Should enforce max limit when loading from persistence")
    }

    // MARK: - Legacy Migration

    func testMigration_FromLegacySelectedMountainId() {
        // Simulate legacy state
        UserDefaults.standard.set("legacy-mountain", forKey: "selectedMountainId")
        UserDefaults.standard.removeObject(forKey: testStorageKey)

        let migrated = FavoritesService()

        XCTAssertTrue(migrated.favoriteIds.contains("legacy-mountain"),
                     "Should migrate legacy selected mountain to favorites")
    }
}
