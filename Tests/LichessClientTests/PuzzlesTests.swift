import XCTest

@testable import LichessClient

final class PuzzlesTests: XCTestCase {

  func testDailyPuzzleFetchParsesFields() async throws {
    let client = LichessClient()

    let daily = try await client.getDailyPuzzle()
    XCTAssertFalse(daily.puzzle.id.isEmpty)
    XCTAssertFalse(daily.game.id.isEmpty)
    XCTAssertGreaterThan(daily.puzzle.solution.count, 0)
    XCTAssertGreaterThanOrEqual(daily.game.players.count, 1)
    XCTAssertGreaterThan(daily.puzzle.rating, 0)
  }

  func testGetPuzzleByIdMatchesDaily() async throws {
    let client = LichessClient()

    let daily = try await client.getDailyPuzzle()
    let byId = try await client.getPuzzle(id: daily.puzzle.id)

    XCTAssertEqual(daily.puzzle.id, byId.puzzle.id)
    // sanity check a few fields exist as expected
    XCTAssertGreaterThan(byId.puzzle.solution.count, 0)
    XCTAssertFalse(byId.game.id.isEmpty)
  }
}

