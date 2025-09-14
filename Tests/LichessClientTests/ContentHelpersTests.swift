import XCTest

@testable import LichessClient

final class ContentHelpersTests: XCTestCase {

  func testSplitAndJoinPGN() throws {
    let game1 = """
    [Event "Casual Game"]
    [Site "?"]
    [Result "*"]

    1. e4 e5 2. Nf3 Nc6 *
    """
    let game2 = """
    [Event "Another Game"]
    [Site "?"]
    [Result "*"]

    1. d4 d5 2. c4 e6 *
    """
    let multi = PGNUtilities.joinGames([game1, game2])
    let parts = PGNUtilities.splitGames(multi)
    XCTAssertEqual(parts.count, 2)
    XCTAssertTrue(parts[0].contains("Casual Game"))
    XCTAssertTrue(parts[1].contains("Another Game"))
  }

  func testParseTags() throws {
    let pgn = """
    [Event "Test"]
    [Site "https://lichess.org"]
    [Result "*"]

    1. e4 *
    """
    let tags = PGNUtilities.parseTags(from: pgn)
    XCTAssertEqual(tags["Event"], "Test")
    XCTAssertEqual(tags["Site"], "https://lichess.org")
    XCTAssertEqual(tags["Result"], "*")
  }

  func testStripCommentsAndNAGs() throws {
    let pgn = "1. e4 { good move } e5 (1... c5 $5) 2. Nf3 $1 *"
    let stripped = PGNUtilities.stripCommentsVariationsAndNAGs(pgn)
    XCTAssertFalse(stripped.contains("{"))
    XCTAssertFalse(stripped.contains("("))
    XCTAssertFalse(stripped.contains("$"))
    XCTAssertTrue(stripped.contains("e4"))
  }
}

