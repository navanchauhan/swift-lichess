import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class StreamersTests: XCTestCase {
  struct Transport: ClientTransport { let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?); func send(_ r: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) { try await handler(r, body, baseURL, operationID) } }

  func testGetLiveStreamersMapsFields() async throws {
    let json = """
    [{"id":"s1","name":"Alice"}]
    """
    // Generator expects a flattened tuple object with LightUser fields and extra keys at the same level
    let wired = "[{\"id\":\"alice\",\"name\":\"Alice\",\"stream\":{\"service\":\"twitch\",\"status\":\"Playing\"},\"streamer\":{\"name\":\"Alice\",\"twitch\":\"https://twitch.tv/a\"}}]"
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "streamerLive")
      return (HTTPResponse(status: .ok), HTTPBody(wired))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let list = try await client.getLiveStreamers()
    XCTAssertEqual(list.first?.id, "alice")
    XCTAssertEqual(list.first?.service, "twitch")
  }
}
