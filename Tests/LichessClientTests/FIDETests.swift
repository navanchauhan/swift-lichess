import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class FIDETests: XCTestCase {
  struct Transport: ClientTransport { let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?); func send(_ r: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) { try await handler(r, body, baseURL, operationID) } }

  func testGetFIDEPlayerMapsFields() async throws {
    let json = """
    {"id":123,"name":"Alice","title":"IM","federation":"USA","year":1999,"inactive":0,"standard":2400,"rapid":2350,"blitz":2380}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "fidePlayerGet"); return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let p = try await client.getFIDEPlayer(id: 123)
    XCTAssertEqual(p.name, "Alice"); XCTAssertEqual(p.title, "IM"); XCTAssertEqual(p.standard, 2400)
  }

  func testSearchFIDEPlayers() async throws {
    let json = """
    [{"id":1,"name":"A","federation":"USA"},{"id":2,"name":"B","federation":"NOR"}]
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "fidePlayerSearch"); return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let res = try await client.searchFIDEPlayers(query: "al")
    XCTAssertEqual(res.count, 2)
  }
}
