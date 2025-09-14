import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class UsersTests: XCTestCase {

  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testGetUserMapsFields() async throws {
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiUser")
      let json = "{\"id\":\"abc\",\"username\":\"Alice\",\"title\":\"GM\",\"createdAt\":1000,\"seenAt\":2000,\"verified\":true,\"disabled\":false,\"url\":\"https://lichess.org/@/Alice\",\"playing\":\"game\",\"streaming\":true}"
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let u = try await client.getUser(username: "Alice")
    XCTAssertEqual(u.id, "abc")
    XCTAssertEqual(u.username, "Alice")
    XCTAssertEqual(u.title, "GM")
    XCTAssertNotNil(u.createdAt)
    XCTAssertNotNil(u.seenAt)
    XCTAssertEqual(u.verified, true)
    XCTAssertEqual(u.disabled, false)
    XCTAssertEqual(u.url, "https://lichess.org/@/Alice")
    XCTAssertEqual(u.playing, "game")
    XCTAssertEqual(u.streaming, true)
  }

  func testGetMyProfile() async throws {
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "accountMe")
      let json = "{\"id\":\"me\",\"username\":\"Bob\"}"
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let me = try await client.getMyProfile()
    XCTAssertEqual(me.id, "me")
    XCTAssertEqual(me.username, "Bob")
  }

  func testGetMyEmail() async throws {
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "accountEmail")
      let json = "{\"email\":\"me@example.com\"}"
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let email = try await client.getMyEmail()
    XCTAssertEqual(email, "me@example.com")
  }
}

