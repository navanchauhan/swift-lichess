import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

struct ClosureTransport: ClientTransport {
  let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
  func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
    try await handler(request, body, baseURL, operationID)
  }
}

final class OAuthTests: XCTestCase {

  func testS256Vector() {
    // RFC 7636 example vector
    let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
    let expected = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
    XCTAssertEqual(LichessClient.s256Challenge(for: verifier), expected)
  }

  func testAuthorizationURLBuilds() {
    let pkce = LichessClient.PKCE(codeVerifier: "v", codeChallenge: "c")
    let url = LichessClient().buildAuthorizationURL(
      clientID: "myapp",
      redirectURI: URL(string: "myapp://callback")!,
      scopes: ["challenge:write", "email:read"],
      state: "xyz",
      username: "user",
      pkce: pkce
    )
    let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    XCTAssertEqual(comps.path, "/oauth")
    let q = Dictionary(uniqueKeysWithValues: comps.queryItems!.map { ($0.name, $0.value ?? "") })
    XCTAssertEqual(q["code_challenge_method"], "S256")
    XCTAssertEqual(q["code_challenge"], "c")
    XCTAssertEqual(q["client_id"], "myapp")
    XCTAssertEqual(q["redirect_uri"], "myapp://callback")
    XCTAssertEqual(q["state"], "xyz")
    XCTAssertEqual(q["username"], "user")
    XCTAssertEqual(q["scope"], "challenge:write email:read")
  }

  func testExchangeUsesFormBody() async throws {
    let transport = ClosureTransport { request, body, _, operationID in
      XCTAssertEqual(operationID, "apiToken")
      XCTAssertEqual(request.method, .post)
      XCTAssertEqual(request.headerFields[.contentType], "application/x-www-form-urlencoded")
      if let body = body {
        let string = try await String(collecting: body, upTo: 4096)
        XCTAssertTrue(string.contains("grant_type=authorization_code"))
        XCTAssertTrue(string.contains("code=abc"))
        XCTAssertTrue(string.contains("code_verifier=verif"))
        XCTAssertTrue(string.contains("redirect_uri=myapp%3A%2F%2Fcb"))
        XCTAssertTrue(string.contains("client_id=myapp"))
      } else {
        XCTFail("Missing body")
      }
      let json = "{\"token_type\":\"Bearer\",\"access_token\":\"tkn\",\"expires_in\":3600}"
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let token = try await client.exchangeCodeForToken(
      clientID: "myapp",
      code: "abc",
      redirectURI: URL(string: "myapp://cb")!,
      codeVerifier: "verif"
    )
    XCTAssertEqual(token.accessToken, "tkn")
    XCTAssertEqual(token.tokenType, "Bearer")
    XCTAssertEqual(token.expiresIn, 3600)
  }

  func testRevokeCallsDelete() async throws {
    final class Counter { var deletes = 0 }
    let ctr = Counter()
    let transport = ClosureTransport { _, _, _, operationID in
      if operationID == "apiTokenDelete" { ctr.deletes += 1; return (HTTPResponse(status: .noContent), nil) }
      return (HTTPResponse(status: .ok), nil)
    }
    let client = LichessClient(configuration: .init(transport: transport))
    try await client.revokeAccessToken()
    XCTAssertEqual(ctr.deletes, 1)
  }
}
