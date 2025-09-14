import XCTest
@testable import LichessClient
import HTTPTypes

final class DiagnosticsTests: XCTestCase {

  func testRetryMiddlewareRetriesOnServerError() async throws {
    let mw = RetryMiddleware(policy: .init(maxAttempts: 2, baseDelay: 0.01, jitter: 0, retryOnStatusCodes: [500]))
    var attempts = 0
    var req = HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/")
    let (_, _) = try await mw.intercept(req, body: nil, baseURL: URL(string: "https://example.com")!, operationID: "op") { request, _, _ in
      attempts += 1
      if attempts == 1 {
        return (HTTPResponse(status: .init(code: 500)), nil)
      }
      return (HTTPResponse(status: .ok), nil)
    }
    XCTAssertEqual(attempts, 2)
  }

  func testRateLimitMiddlewareHonorsRetryAfterZero() async throws {
    let mw = RateLimitMiddleware(policy: .init(maxRetries: 1, defaultDelaySeconds: 1, respectRetryAfterHeader: true))
    var attempts = 0
    var req = HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/")
    let start = Date()
    let (_, _) = try await mw.intercept(req, body: nil, baseURL: URL(string: "https://example.com")!, operationID: "op") { request, _, _ in
      attempts += 1
      if attempts == 1 {
        var resp = HTTPResponse(status: .init(code: 429))
        resp.headerFields[HTTPField.Name("Retry-After")!] = "0"
        return (resp, nil)
      }
      return (HTTPResponse(status: .ok), nil)
    }
    let elapsed = Date().timeIntervalSince(start)
    XCTAssertEqual(attempts, 2)
    XCTAssertLessThan(elapsed, 0.5) // should not sleep due to Retry-After: 0
  }

  func testLoggingMiddlewareSendsToSink() async throws {
    var lines: [String] = []
    let cfg = LoggingConfiguration(enabled: true, level: .info, logBodies: false, redactHeaders: [.authorization]) { s in
      lines.append(s)
    }
    let mw = LoggingMiddleware(configuration: cfg)
    var req = HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/abc")
    req.headerFields[.authorization] = "Bearer token"

    let (resp, _) = try await mw.intercept(req, body: nil, baseURL: URL(string: "https://example.com")!, operationID: "testOp") { request, _, _ in
      return (HTTPResponse(status: .ok), nil)
    }
    XCTAssertEqual(resp.status, .ok)
    XCTAssertTrue(lines.contains { $0.contains("testOp") })
    XCTAssertTrue(lines.contains { $0.contains("GET") })
    XCTAssertTrue(lines.contains { $0.contains("200") })
    // ensure redaction applied
    XCTAssertFalse(lines.contains { $0.contains("Bearer token") })
  }
}

