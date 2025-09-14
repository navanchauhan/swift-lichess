import Foundation
import CryptoKit
import OpenAPIRuntime

extension LichessClient {
  public struct PKCE: Sendable, Hashable {
    public let codeVerifier: String
    public let codeChallenge: String
  }

  public struct OAuthToken: Sendable, Hashable {
    public let tokenType: String
    public let accessToken: String
    public let expiresIn: Int
    public let expiresAt: Date
  }

  public static func generatePKCE(verifierLength: Int = 64) -> PKCE {
    let length = max(43, min(verifierLength, 128))
    var bytes = [UInt8](repeating: 0, count: length)
    for i in 0..<length { bytes[i] = UInt8.random(in: 0...255) }
    let verifier = base64urlNoPadding(Data(bytes))
    let challenge = s256Challenge(for: verifier)
    return PKCE(codeVerifier: verifier, codeChallenge: challenge)
  }

  public static func s256Challenge(for codeVerifier: String) -> String {
    let digest = SHA256.hash(data: Data(codeVerifier.utf8))
    return base64urlNoPadding(Data(digest))
  }

  static func base64urlNoPadding(_ data: Data) -> String {
    let base = data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    return base
  }

  public func buildAuthorizationURL(
    clientID: String,
    redirectURI: URL,
    scopes: [String],
    state: String,
    username: String? = nil,
    pkce: PKCE
  ) -> URL {
    var components = URLComponents(url: URL(string: "https://lichess.org/oauth")!, resolvingAgainstBaseURL: false)!
    let items: [URLQueryItem?] = [
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "redirect_uri", value: redirectURI.absoluteString),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
      URLQueryItem(name: "code_challenge", value: pkce.codeChallenge),
      URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
      URLQueryItem(name: "state", value: state),
      username.map { URLQueryItem(name: "username", value: $0) }
    ]
    components.queryItems = items.compactMap { $0 }
    return components.url!
  }

  public func exchangeCodeForToken(
    clientID: String,
    code: String,
    redirectURI: URL,
    codeVerifier: String
  ) async throws -> OAuthToken {
    let body: Operations.apiToken.Input.Body = .urlEncodedForm(.init(
      grant_type: .authorization_code,
      code: code,
      code_verifier: codeVerifier,
      redirect_uri: redirectURI.absoluteString,
      client_id: clientID
    ))
    let response = try await underlyingClient.apiToken(body: body)
    switch response {
    case .ok(let ok):
      let payload = try ok.body.json
      return OAuthToken(
        tokenType: payload.token_type,
        accessToken: payload.access_token,
        expiresIn: payload.expires_in,
        expiresAt: Date().addingTimeInterval(TimeInterval(payload.expires_in))
      )
    case .badRequest(let bad):
      throw LichessClientError.parsingError(error: NSError(domain: "LichessOAuth", code: 400, userInfo: ["error": String(describing: bad)]))
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func revokeAccessToken() async throws {
    let response = try await underlyingClient.apiTokenDelete()
    switch response {
    case .noContent:
      return
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public struct TokenTestResult: Sendable, Hashable {
    public let userId: String?
    public let scopes: [String]
    public let expiresAt: Date?
  }

  public func testTokens(_ tokens: [String]) async throws -> [String: TokenTestResult?] {
    let input = tokens.joined(separator: "\n")
    let response = try await underlyingClient.tokenTest(
      body: .plainText(.init(input))
    )
    switch response {
    case .ok(let ok):
      let dict = try ok.body.json.additionalProperties
      var results: [String: TokenTestResult?] = [:]
      for (token, value) in dict {
        switch value {
        case .case1(let info):
          let scopes = (info.scopes ?? "").split(separator: ",").map { String($0) }.filter { !$0.isEmpty }
          let expiresAt: Date?
          if let ms = info.expires { expiresAt = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0) } else { expiresAt = nil }
          results[token] = .some(.init(userId: info.userId, scopes: scopes, expiresAt: expiresAt))
        case .case2:
          results[token] = nil
        case .none:
          results[token] = nil
        }
      }
      return results
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: - Authorization endpoint wrapper
  // Typically you should use `buildAuthorizationURL(...)` and open it in a browser.
  // This wrapper exists to provide parity with the generated `GET /oauth` operation.
  @discardableResult
  public func requestAuthorization(
    clientID: String,
    redirectURI: URL,
    scopes: [String],
    state: String,
    username: String? = nil,
    pkce: PKCE
  ) async throws -> Bool {
    let query = Operations.oauth.Input.Query(
      response_type: .code,
      client_id: clientID,
      redirect_uri: redirectURI.absoluteString,
      code_challenge_method: .S256,
      code_challenge: pkce.codeChallenge,
      scope: scopes.isEmpty ? nil : scopes.joined(separator: " "),
      username: username,
      state: state
    )
    let response = try await underlyingClient.oauth(query: query)
    switch response {
    case .ok:
      return true
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}
