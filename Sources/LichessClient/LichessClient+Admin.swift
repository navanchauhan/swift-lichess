import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: - Admin
  /// Create or reuse `challenge:write` tokens for a list of usernames.
  /// Note: This endpoint is restricted to Lichess administrators.
  public func adminCreateChallengeTokens(usernames: [String], description: String) async throws -> [String: String] {
    let users = usernames.joined(separator: ",")
    let body = Operations.adminChallengeTokens.Input.Body.urlEncodedForm(.init(users: users, description: description))
    let resp = try await underlyingClient.adminChallengeTokens(body: body)
    switch resp {
    case .ok(let ok):
      let map = try ok.body.json.additionalProperties
      return map
    case .badRequest(let bad):
      if case let .json(err) = bad.body {
        throw LichessClientError.parsingError(error: NSError(domain: "AdminChallengeTokens", code: 400, userInfo: [NSLocalizedDescriptionKey: err.error ?? "Bad Request"]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }
}

