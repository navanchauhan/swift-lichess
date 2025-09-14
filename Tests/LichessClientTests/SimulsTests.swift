import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class SimulsTests: XCTestCase {
  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) { try await handler(request, body, baseURL, operationID) }
  }

  func testGetSimulsMapsLists() async throws {
    let json = """
    {"created":[{"id":"s1","host":{"id":"h","name":"Host"},"name":"N","fullName":"FN","variants":[{"name":"Blitz"}],"isCreated":true,"isFinished":false,"isRunning":false,"nbApplicants":0,"nbPairings":0}],
      "started":[],"finished":[],"pending":[]}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiSimul")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let res = try await client.getSimuls()
    XCTAssertEqual(res.created.first?.id, "s1")
    XCTAssertEqual(res.created.first?.host.name, "Host")
  }
}

