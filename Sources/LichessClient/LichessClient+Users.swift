import Foundation

extension LichessClient {
  public struct PublicUser: Sendable, Hashable {
    public let id: String
    public let username: String
    public let title: String?
    public let createdAt: Date?
    public let seenAt: Date?
    public let verified: Bool?
    public let disabled: Bool?
    public let url: String?
    public let playing: String?
    public let streaming: Bool?
  }

  private func toDate(ms: Int64?) -> Date? {
    guard let ms else { return nil }
    return Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
  }

  private func mapUserExtended(_ user: Components.Schemas.UserExtended) -> PublicUser {
    let u = user.value1
    let extra = user.value2
    return PublicUser(
      id: u.id,
      username: u.username,
      title: u.title?.rawValue,
      createdAt: toDate(ms: u.createdAt),
      seenAt: toDate(ms: u.seenAt),
      verified: u.verified,
      disabled: u.disabled,
      url: extra.url,
      playing: extra.playing,
      streaming: extra.streaming
    )
  }

  public func getUser(username: String, includeTrophies: Bool = false) async throws -> PublicUser {
    let response = try await underlyingClient.apiUser(
      path: .init(username: username),
      query: .init(trophies: includeTrophies)
    )
    switch response {
    case .ok(let ok):
      let payload = try ok.body.json
      return mapUserExtended(payload)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func getMyProfile() async throws -> PublicUser {
    let response = try await underlyingClient.accountMe()
    switch response {
    case .ok(let ok):
      let payload = try ok.body.json
      return mapUserExtended(payload)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func getMyEmail() async throws -> String? {
    let response = try await underlyingClient.accountEmail()
    switch response {
    case .ok(let ok):
      return try ok.body.json.email
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}

