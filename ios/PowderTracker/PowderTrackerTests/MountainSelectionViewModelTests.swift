import XCTest
@testable import PowderTracker

/// Tests for MountainSelectionViewModel - mountain picker logic
@MainActor
final class MountainSelectionViewModelTests: XCTestCase {

    private var viewModel: MountainSelectionViewModel!

    override func setUp() async throws {
        viewModel = MountainSelectionViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - Initial State

    func testInitialState_EmptyMountains() {
        XCTAssertTrue(viewModel.mountains.isEmpty,
                     "Should start with no mountains")
    }

    func testInitialState_NoSelection() {
        XCTAssertNil(viewModel.selectedMountain,
                    "Should have no selection initially")
    }

    func testInitialState_NotLoading() {
        XCTAssertFalse(viewModel.isLoading,
                      "Should not be loading initially")
    }

    func testInitialState_NoError() {
        XCTAssertNil(viewModel.error,
                    "Should have no error initially")
    }

    func testInitialState_EmptyScores() {
        XCTAssertTrue(viewModel.mountainScores.isEmpty,
                     "Should have no scores initially")
    }

    func testInitialState_EmptyConditions() {
        XCTAssertTrue(viewModel.mountainConditions.isEmpty,
                     "Should have no conditions initially")
    }

    // MARK: - Select Mountain

    func testSelectMountain_UpdatesSelection() {
        let mountain = Mountain.mock(id: "baker", name: "Mt. Baker")

        viewModel.selectMountain(mountain)

        XCTAssertNotNil(viewModel.selectedMountain)
        XCTAssertEqual(viewModel.selectedMountain?.id, "baker")
        XCTAssertEqual(viewModel.selectedMountain?.name, "Mt. Baker")
    }

    func testSelectMountain_OverridesPreviousSelection() {
        let mountain1 = Mountain.mock(id: "baker", name: "Mt. Baker")
        let mountain2 = Mountain.mock(id: "crystal", name: "Crystal Mountain")

        viewModel.selectMountain(mountain1)
        viewModel.selectMountain(mountain2)

        XCTAssertEqual(viewModel.selectedMountain?.id, "crystal",
                      "Should replace previous selection")
    }

    // MARK: - Get Score

    func testGetScore_ReturnsStoredScore() {
        let mountain = Mountain.mock(id: "baker")
        viewModel.mountainScores["baker"] = 85.5

        let score = viewModel.getScore(for: mountain)

        XCTAssertEqual(score, 85.5)
    }

    func testGetScore_ReturnsNilForUnknown() {
        let mountain = Mountain.mock(id: "unknown")

        let score = viewModel.getScore(for: mountain)

        XCTAssertNil(score)
    }

    // MARK: - Get Conditions

    func testGetConditions_ReturnsNilForUnknown() {
        let mountain = Mountain.mock(id: "unknown")

        let conditions = viewModel.getConditions(for: mountain)

        XCTAssertNil(conditions)
    }

    // MARK: - Region Filtering

    func testWashingtonMountains_FiltersCorrectly() {
        viewModel.mountains = [
            Mountain.mock(id: "baker", name: "Mt. Baker", region: "washington"),
            Mountain.mock(id: "crystal", name: "Crystal", region: "washington"),
            Mountain.mock(id: "hood", name: "Mt. Hood", region: "oregon"),
            Mountain.mock(id: "brundage", name: "Brundage", region: "idaho")
        ]

        let washingtonMountains = viewModel.washingtonMountains

        XCTAssertEqual(washingtonMountains.count, 2)
        XCTAssertTrue(washingtonMountains.allSatisfy { $0.region == "washington" })
    }

    func testOregonMountains_FiltersCorrectly() {
        viewModel.mountains = [
            Mountain.mock(id: "baker", region: "washington"),
            Mountain.mock(id: "hood", region: "oregon"),
            Mountain.mock(id: "bachelor", region: "oregon")
        ]

        let oregonMountains = viewModel.oregonMountains

        XCTAssertEqual(oregonMountains.count, 2)
        XCTAssertTrue(oregonMountains.allSatisfy { $0.region == "oregon" })
    }

    func testIdahoMountains_FiltersCorrectly() {
        viewModel.mountains = [
            Mountain.mock(id: "baker", region: "washington"),
            Mountain.mock(id: "brundage", region: "idaho"),
            Mountain.mock(id: "schweitzer", region: "idaho")
        ]

        let idahoMountains = viewModel.idahoMountains

        XCTAssertEqual(idahoMountains.count, 2)
        XCTAssertTrue(idahoMountains.allSatisfy { $0.region == "idaho" })
    }

    func testRegionFilter_EmptyWhenNoMountainsInRegion() {
        viewModel.mountains = [
            Mountain.mock(id: "baker", region: "washington")
        ]

        XCTAssertTrue(viewModel.oregonMountains.isEmpty)
        XCTAssertTrue(viewModel.idahoMountains.isEmpty)
    }

    func testRegionFilter_AllRegionsEmptyWhenNoMountains() {
        viewModel.mountains = []

        XCTAssertTrue(viewModel.washingtonMountains.isEmpty)
        XCTAssertTrue(viewModel.oregonMountains.isEmpty)
        XCTAssertTrue(viewModel.idahoMountains.isEmpty)
    }

    // MARK: - Score Storage

    func testScoreStorage_MultipleMountains() {
        viewModel.mountainScores = [
            "baker": 92.0,
            "crystal": 78.5,
            "stevens": 65.0
        ]

        let baker = Mountain.mock(id: "baker")
        let crystal = Mountain.mock(id: "crystal")
        let stevens = Mountain.mock(id: "stevens")

        XCTAssertEqual(viewModel.getScore(for: baker), 92.0)
        XCTAssertEqual(viewModel.getScore(for: crystal), 78.5)
        XCTAssertEqual(viewModel.getScore(for: stevens), 65.0)
    }

    func testScoreStorage_OverwriteScore() {
        viewModel.mountainScores["baker"] = 80.0
        viewModel.mountainScores["baker"] = 95.0

        let baker = Mountain.mock(id: "baker")
        XCTAssertEqual(viewModel.getScore(for: baker), 95.0,
                      "Should return updated score")
    }

    // MARK: - Mountain List Operations

    func testMountainList_Assignment() {
        let mountains = Mountain.mockList(count: 5)

        viewModel.mountains = mountains

        XCTAssertEqual(viewModel.mountains.count, 5)
    }

    func testMountainList_UpdatePreservesSelection() {
        let mountain = Mountain.mock(id: "baker")
        viewModel.selectMountain(mountain)

        // Update mountains list
        viewModel.mountains = Mountain.mockList(count: 10)

        // Selection should persist (it's stored independently)
        XCTAssertEqual(viewModel.selectedMountain?.id, "baker",
                      "Selection should persist after mountain list update")
    }
}
