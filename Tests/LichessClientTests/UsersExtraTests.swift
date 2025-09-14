import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class UsersExtraTests: XCTestCase {
  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) { try await handler(request, body, baseURL, operationID) }
  }

  func testUsersStatusMapsFields() async throws {
    let json = """
    [{"id":"u1","name":"Alice","online":true,"playing":false,"streaming":false,"patron":true}]
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiUsersStatus")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let s = try await client.getUsersStatus(ids: ["u1"]) 
    XCTAssertEqual(s.first?.name, "Alice")
    XCTAssertEqual(s.first?.online, true)
  }

  func testBulkUsersSendsPlainTextBody() async throws {
    var seenBody = ""
    let json = "[{\"id\":\"u1\",\"username\":\"alice\"}]"
    let transport = Transport { _, body, _, op in
      XCTAssertEqual(op, "apiUsers")
      if let body = body { seenBody = try await String(collecting: body, upTo: 4096) }
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let users = try await client.getUsers(usernames: ["alice"]) 
    XCTAssertTrue(seenBody.contains("alice"))
    XCTAssertEqual(users.first?.username, "alice")
  }

  func testSendInboxEncodesForm() async throws {
    var seen: String = ""
    let transport = Transport { req, body, _, op in
      XCTAssertEqual(op, "inboxUsername")
      XCTAssertEqual(req.method, .post)
      XCTAssertEqual(req.headerFields[.contentType], "application/x-www-form-urlencoded")
      if let body = body { seen = try await String(collecting: body, upTo: 4096) }
      return (HTTPResponse(status: .ok), HTTPBody("{}"))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let ok = try await client.sendPrivateMessage(to: "bob", text: "Hi")
    XCTAssertTrue(ok)
    XCTAssertTrue(seen.contains("text=Hi"))
  }

  func testUserCurrentGamePgnAccept() async throws {
    var accept: String?
    let transport = Transport { req, _, _, op in
      XCTAssertEqual(op, "apiUserCurrentGame")
      accept = req.headerFields[.accept]
      return (HTTPResponse(status: .ok), HTTPBody("[Event \"X\"]\n*\n"))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    _ = try await client.getUserCurrentGame(username: "alice", format: .pgn)
    XCTAssertTrue(accept?.contains("application/x-chess-pgn") ?? false)
  }

  func testNotesMap() async throws {
    let json = """
    [{"from":{"id":"u1","name":"me"},"to":{"id":"u2","name":"you"},"text":"hi","date":1710000000000}]
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "readNote")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let notes = try await client.getNotes(for: "you")
    XCTAssertEqual(notes.first?.text, "hi")
    XCTAssertEqual(notes.first?.from, "me")
  }

  func testUserActivityAsBody() async throws {
    let json = "[{\"interval\":{\"start\":0,\"end\":1}}]"
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiUserActivity")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let body = try await client.getUserActivity(username: "alice")
    var got = false
    for try await chunk in body { XCTAssertFalse(chunk.isEmpty); got = true; break }
    XCTAssertTrue(got)
  }
}
