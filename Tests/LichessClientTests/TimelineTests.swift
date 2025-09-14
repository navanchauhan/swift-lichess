import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class TimelineTests: XCTestCase {
  struct Transport: ClientTransport { let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?); func send(_ r: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) { try await handler(r, body, baseURL, operationID) } }

  func testGetTimelineMapsEntries() async throws {
    let payload = """
    {"entries":[{"type":"follow","date":1,"data":{"u1":"a","u2":"b"}}],"users":{"a":{"id":"a","name":"A"},"b":{"id":"b","name":"B"}}}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "timeline")
      return (HTTPResponse(status: .ok), HTTPBody(payload))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let tl = try await client.getTimeline()
    guard case let .follow(u1, u2) = tl.entries.first else { return XCTFail("wrong entry") }
    XCTAssertEqual(u1, "a"); XCTAssertEqual(u2, "b")
    XCTAssertEqual(tl.users["a"]?.name, "A")
  }
}

