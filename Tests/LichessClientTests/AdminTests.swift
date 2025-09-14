import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class AdminTests: XCTestCase {
  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testAdminChallengeTokensFormAndMapping() async throws {
    var capturedBody: String = ""
    let transport = Transport { req, body, _, op in
      XCTAssertEqual(op, "adminChallengeTokens")
      XCTAssertEqual(req.method, .post)
      XCTAssertEqual(req.headerFields[.contentType], "application/x-www-form-urlencoded")
      if let body = body { capturedBody = try await String(collecting: body, upTo: 2048) }
      let json = "{\"alice\":\"tok1\",\"bob\":\"tok2\"}"
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let map = try await client.adminCreateChallengeTokens(usernames: ["alice","bob"], description: "Bulk pairing")
    XCTAssertTrue(capturedBody.contains("users=alice%2Cbob"))
    XCTAssertTrue(capturedBody.contains("description=Bulk+pairing"))
    XCTAssertEqual(map["alice"], "tok1")
    XCTAssertEqual(map["bob"], "tok2")
  }
}

