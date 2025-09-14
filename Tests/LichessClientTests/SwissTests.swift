import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class SwissTests: XCTestCase {
  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testTeamSwissAcceptHeader() async throws {
    var seenAccept: String?
    let transport = Transport { req, _, _, op in
      XCTAssertEqual(op, "apiTeamSwiss")
      seenAccept = req.headerFields[.accept]
      return (HTTPResponse(status: .ok), HTTPBody("{}\n"))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    _ = try await client.getTeamSwissTournaments(teamId: "lichess", max: 1, status: "created")
    XCTAssertTrue(seenAccept?.contains("application/x-ndjson") ?? false)
  }
}

