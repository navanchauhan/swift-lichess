import XCTest

@testable import LichessClient

final class LichessClientTestsPac: XCTestCase {

  func testTablebaseLookup() async throws {
    let client = LichessClient()

    let tablebaseLookup = try await client.getStandardTablebase(
      fen: "4k3/6KP/8/8/8/8/7p/8_w_-_-_0_1")
    guard let dtm = tablebaseLookup.dtm else {
      XCTAssert(false == true)
      return
    }
    XCTAssert(dtm == 17)

    var found = false
    guard let moves = tablebaseLookup.moves else {
      XCTAssert(true == false)
      return
    }
    for move in moves {
      guard let uci = move.uci else {
        XCTAssert(false == true)
        return
      }
      if uci == "h7h8q" {
        found = true
        break
      }
    }
    XCTAssert(found == true)
  }
}
