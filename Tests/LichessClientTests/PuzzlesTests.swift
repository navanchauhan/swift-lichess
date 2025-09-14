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

  func testNextPuzzleFetchWorksOrSkipsIfUnauthorized() async throws {
    let client = LichessClient()
    do {
      let next = try await client.getNextPuzzle()
      XCTAssertFalse(next.puzzle.id.isEmpty)
      XCTAssertFalse(next.game.id.isEmpty)
    } catch let error as LichessClient.LichessClientError {
      switch error {
      case .undocumentedResponse(let statusCode) where statusCode == 401:
        throw XCTSkip("Requires puzzle:read scope; skipping in anonymous environment")
      default:
        throw error
      }
    } catch {
      throw error
    }
  }
}
