import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class CloudEvalTests: XCTestCase {

  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testCloudEvalCpPV() async throws {
    let json = """
    {"depth":22,"fen":"F","knodes":1234,"pvs":[{"cp":34,"moves":"e2e4 e7e5 g1f3"}]}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiCloudEval")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let res = try await client.getCloudEval(fen: "F")
    XCTAssertNotNil(res)
    XCTAssertEqual(res?.depth, 22)
    XCTAssertEqual(res?.pvs.first?.cp, 34)
    XCTAssertEqual(res?.pvs.first?.moves.prefix(2), ["e2e4","e7e5"])
  }

  func testCloudEvalMatePV() async throws {
    let json = """
    {"depth":30,"fen":"F","knodes":999,"pvs":[{"mate":3,"moves":"h7h8q g8h7 h8g8#"}]}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiCloudEval")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let res = try await client.getCloudEval(fen: "F")
    XCTAssertEqual(res?.pvs.first?.mate, 3)
    XCTAssertTrue(res?.pvs.first?.moves.contains("h8g8#") ?? false)
  }

  func testCloudEvalNotFound() async throws {
    let transport = Transport { _, _, _, _ in
      var resp = HTTPResponse(status: .notFound)
      return (resp, HTTPBody("{\"error\":\"No cloud evaluation available for that position\"}"))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let res = try await client.getCloudEval(fen: "X")
    XCTAssertNil(res)
  }
}

