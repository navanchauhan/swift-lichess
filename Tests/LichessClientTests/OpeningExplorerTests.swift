import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class OpeningExplorerTests: XCTestCase {
  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testMastersGameAcceptHeaderAndBody() async throws {
    var seenAccept: String?
    let transport = Transport { req, _, _, op in
      XCTAssertEqual(op, "openingExplorerMasterGame")
      seenAccept = req.headerFields[.accept]
      return (HTTPResponse(status: .ok), HTTPBody("[Event \"X\"]\n*\n"))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let body = try await client.getOpeningExplorerMastersGamePGN(gameId: "abc")
    var gotLine = false
    for try await chunk in body {
      let line = String(decoding: chunk, as: UTF8.self)
      XCTAssertTrue(line.contains("[Event"))
      gotLine = true
      break
    }
    XCTAssertTrue(gotLine)
    XCTAssertTrue(seenAccept?.contains("application/x-chess-pgn") ?? false)
  }
}

