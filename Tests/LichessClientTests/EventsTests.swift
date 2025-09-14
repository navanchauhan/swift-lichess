import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class EventsTests: XCTestCase {
  func testDecodeIncomingEvent() throws {
    let js1 = "{\"type\":\"gameStart\",\"game\":{\"id\":\"abcd\"}}"
    let js2 = "{\"type\":\"challenge\",\"challenge\":{\"id\":\"xyz\",\"status\":\"created\"}}"
    let e1 = LichessClient.decodeIncomingEvent(from: js1.data(using: .utf8)!)
    if case let .gameStart(g)? = e1 { XCTAssertEqual(g.id, "abcd") } else { XCTFail("wrong type") }
    let e2 = LichessClient.decodeIncomingEvent(from: js2.data(using: .utf8)!)
    if case let .challenge(ch)? = e2 { XCTAssertEqual(ch.id, "xyz") } else { XCTFail("wrong type") }
  }

  func testStreamIncomingEventsReturnsNDJSON() async throws {
    struct Transport: ClientTransport { let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?); func send(_ r: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) { try await handler(r, body, baseURL, operationID) } }
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiStreamEvent")
      return (HTTPResponse(status: .ok), HTTPBody("{\"type\":\"gameStart\",\"game\":{\"id\":\"g1\"}}\n"))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let body = try await client.streamIncomingEvents()
    var got = false
    for try await item in Streaming.ndjsonStream(from: body, as: DecodableEvent.self) {
      XCTAssertEqual(item.type, "gameStart"); got = true; break
    }
    XCTAssertTrue(got)
  }

  struct DecodableEvent: Decodable { let type: String }
}

