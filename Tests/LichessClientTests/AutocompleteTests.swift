import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class AutocompleteTests: XCTestCase {
  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testAutocompleteReturnsUsernamesList() async throws {
    let json = "[\"navan\",\"navanchauhan\"]"
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiPlayerAutocomplete")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let res = try await client.autocompletePlayers(term: "nav")
    switch res {
    case .usernames(let names):
      XCTAssertTrue(names.contains("navan"))
    default:
      XCTFail("Expected usernames variant")
    }
  }

  func testAutocompleteReturnsUsersObject() async throws {
    let json = """
    {"result":[{"id":"u1","name":"Alice","title":"WGM","patron":true,"online":true}]}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiPlayerAutocomplete")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let res = try await client.autocompletePlayers(term: "a", object: true)
    switch res {
    case .users(let users):
      XCTAssertEqual(users.first?.name, "Alice")
      XCTAssertEqual(users.first?.title, "WGM")
      XCTAssertEqual(users.first?.online, true)
    default:
      XCTFail("Expected users variant")
    }
  }
}

