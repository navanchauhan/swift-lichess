import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class CrosstableTests: XCTestCase {

  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testGetCrosstableMapsFields() async throws {
    let json = """
    {"users":{"alice":10.5,"bob":9.5},"nbGames":20}
    """
    let transport = Transport { req, _, _, op in
      XCTAssertEqual(op, "apiCrosstable")
      XCTAssertTrue((req.path ?? "").contains("/api/crosstable/alice/bob"))
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let ct = try await client.getCrosstable(user1: "alice", user2: "bob")
    XCTAssertEqual(ct.nbGames, 20)
    XCTAssertEqual(ct.scores["alice"], 10.5)
    XCTAssertEqual(ct.scores["bob"], 9.5)
  }
}
