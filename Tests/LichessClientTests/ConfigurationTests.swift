import XCTest
import HTTPTypes
import OpenAPIRuntime
@testable import LichessClient

final class ConfigurationTests: XCTestCase {

  func testTokenAuthMiddlewareSetsAuthorization() async throws {
    let mw = TokenAuthMiddleware(token: "abc123")
    var capturedAuth: String?
    _ = try await mw.intercept(
      HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
      body: nil,
      baseURL: URL(string: "https://example.com")!,
      operationID: "op",
      next: { req, _, _ in
        capturedAuth = req.headerFields[.authorization]
        return (HTTPResponse(status: .ok), nil)
      }
    )
    XCTAssertEqual(capturedAuth, "Bearer abc123")
  }

  func testUserAgentMiddlewareSetsHeader() async throws {
    let mw = UserAgentMiddleware(userAgent: "swift-lichess-tests/1.0")
    var capturedUA: String?
    _ = try await mw.intercept(
      HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
      body: nil,
      baseURL: URL(string: "https://example.com")!,
      operationID: "op",
      next: { req, _, _ in
        capturedUA = req.headerFields[.userAgent]
        return (HTTPResponse(status: .ok), nil)
      }
    )
    XCTAssertEqual(capturedUA, "swift-lichess-tests/1.0")
  }
}
