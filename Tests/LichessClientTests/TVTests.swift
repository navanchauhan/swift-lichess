import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class TVTests: XCTestCase {

  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testGetTVChannelsMapsFields() async throws {
    // Minimal valid JSON payload for tvChannels
    let json = """
    {"bot":{"user":{"id":"u1","name":"Alice"},"rating":2500,"gameId":"g1","color":"white"},
     "blitz":{"user":{"id":"u2","name":"Bob"},"rating":2800,"gameId":"g2","color":"black"},
     "racingKings":{"user":{"id":"u3","name":"C"},"rating":2000,"gameId":"g3","color":"white"},
     "ultraBullet":{"user":{"id":"u4","name":"D"},"rating":1600,"gameId":"g4","color":"white"},
     "bullet":{"user":{"id":"u5","name":"E"},"rating":3000,"gameId":"g5","color":"black"},
     "classical":{"user":{"id":"u6","name":"F"},"rating":2200,"gameId":"g6","color":"white"},
     "threeCheck":{"user":{"id":"u7","name":"G"},"rating":2100,"gameId":"g7","color":"black"},
     "antichess":{"user":{"id":"u8","name":"H"},"rating":2300,"gameId":"g8","color":"white"},
     "computer":{"user":{"id":"u9","name":"I"},"rating":1900,"gameId":"g9","color":"black"},
     "horde":{"user":{"id":"u10","name":"J"},"rating":1950,"gameId":"g10","color":"white"},
     "rapid":{"user":{"id":"u11","name":"K"},"rating":2400,"gameId":"g11","color":"white"},
     "atomic":{"user":{"id":"u12","name":"L"},"rating":1800,"gameId":"g12","color":"black"},
     "crazyhouse":{"user":{"id":"u13","name":"M"},"rating":2050,"gameId":"g13","color":"white"},
     "chess960":{"user":{"id":"u14","name":"N"},"rating":2150,"gameId":"g14","color":"black"},
     "kingOfTheHill":{"user":{"id":"u15","name":"O"},"rating":2250,"gameId":"g15","color":"white"},
     "best":{"user":{"id":"u16","name":"P"},"rating":2850,"gameId":"g16","color":"black"}}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "tvChannels")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let chans = try await client.getTVChannels()
    XCTAssertEqual(chans.entries[.bot]?.user.name, "Alice")
    XCTAssertEqual(chans.entries[.blitz]?.rating, 2800)
    XCTAssertEqual(chans.entries.count, 16)
  }

  func testTVChannelGamesAcceptHeader() async throws {
    var seenAccept: String?
    let transport = Transport { req, _, _, op in
      XCTAssertEqual(op, "tvChannelGames")
      seenAccept = req.headerFields[.accept]
      return (HTTPResponse(status: .ok), HTTPBody("[{}]\n"))
    }
    let client = LichessClient(configuration: .init(transport: transport))

    _ = try await client.getTVChannelGames(channel: "blitz", format: .ndjson, nb: 1)
    XCTAssertTrue(seenAccept?.contains("application/x-ndjson") ?? false)
  }

  struct MinimalFeed: Decodable { let t: String? }
  func testStreamTVChannelFeedReturnsNDJSON() async throws {
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "tvChannelFeed")
      return (HTTPResponse(status: .ok), HTTPBody("{\"t\":\"fen\"}\n"))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let body = try await client.streamTVChannelFeed(channel: "rapid")
    var gotLine = false
    for try await item in Streaming.ndjsonStream(from: body, as: MinimalFeed.self) {
      gotLine = true
      XCTAssertEqual(item.t, "fen")
      break
    }
    XCTAssertTrue(gotLine)
  }
}
