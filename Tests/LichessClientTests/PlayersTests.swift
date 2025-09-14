import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class PlayersTests: XCTestCase {

  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testGetLeaderboardMapsFields() async throws {
    let json = """
    {"users":[{"id":"u1","username":"Alice","perfs":{"blitz":{"rating":2900,"progress":5}},"title":"GM"}]}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "playerTopNbPerfType")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let list = try await client.getLeaderboard(perfType: "blitz", nb: 1)
    XCTAssertEqual(list.count, 1)
    XCTAssertEqual(list.first?.username, "Alice")
    XCTAssertEqual(list.first?.rating, 2900)
    XCTAssertEqual(list.first?.title, "GM")
  }

  func testGetAllTop10BuildsDictionary() async throws {
    // Provide minimal payload: all fields required by Top10s, mostly empty arrays except bullet
    let json = """
    {"bullet":[{"id":"u1","username":"A","perfs":{"bullet":{"rating":3200,"progress":10}}}],
     "blitz":[],"rapid":[],"classical":[],"ultraBullet":[],"crazyhouse":[],"chess960":[],
     "kingOfTheHill":[],"threeCheck":[],"antichess":[],"atomic":[],"horde":[],"racingKings":[]}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "player")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let top = try await client.getAllTop10()
    XCTAssertEqual(top["bullet"]?.first?.rating, 3200)
    XCTAssertEqual(top.keys.count, 13)
  }
}

