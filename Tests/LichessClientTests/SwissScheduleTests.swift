import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class SwissScheduleTests: XCTestCase {
  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testScheduleNextRoundReturnsTrueOn204() async throws {
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiSwissScheduleNextRound")
      return (HTTPResponse(status: .noContent), nil)
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let ok = try await client.scheduleNextSwissRound(id: "sw1", dateMS: 1712345678901)
    XCTAssertTrue(ok)
  }
}

