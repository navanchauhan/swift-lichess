import Foundation

extension LichessClient {
  // MARK: - Autocomplete
  public enum AutocompleteResult: Sendable, Hashable { case usernames([String]); case users([AutocompleteUser]) }

  public struct AutocompleteUser: Sendable, Hashable {
    public let id: String
    public let name: String
    public let title: String?
    public let patron: Bool?
    public let flair: String?
    public let online: Bool?
  }

  public func autocompletePlayers(
    term: String,
    object: Bool? = nil,
    names: Bool? = nil,
    friend: Bool? = nil,
    team: String? = nil,
    tour: String? = nil,
    swiss: String? = nil
  ) async throws -> AutocompleteResult {
    let resp = try await underlyingClient.apiPlayerAutocomplete(
      query: .init(term: term, object: object, names: names, friend: friend, team: team, tour: tour, swiss: swiss)
    )
    switch resp {
    case .ok(let ok):
      switch try ok.body.json {
      case .case1(let names):
        return .usernames(names)
      case .case2(let payload):
        let users: [AutocompleteUser] = (payload.result ?? []).map { lu in
          let u = lu.value1
          return AutocompleteUser(
            id: u.id,
            name: u.name,
            title: u.title?.rawValue,
            patron: u.patron,
            flair: u.flair,
            online: lu.value2.online
          )
        }
        return .users(users)
      }
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }
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
