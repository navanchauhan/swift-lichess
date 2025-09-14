import Foundation
import OpenAPIRuntime

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

  // MARK: - Bulk users
  public func getUsers(usernames: [String]) async throws -> [PublicUser] {
    let body = usernames.joined(separator: "\n")
    let resp = try await underlyingClient.apiUsers(body: .plainText(HTTPBody(body)))
    switch resp {
    case .ok(let ok):
      let list = try ok.body.json
      return list.map { u in
        PublicUser(
          id: u.id,
          username: u.username,
          title: u.title?.rawValue,
          createdAt: toDate(ms: u.createdAt),
          seenAt: toDate(ms: u.seenAt),
          verified: u.verified,
          disabled: u.disabled,
          url: nil,
          playing: nil,
          streaming: nil
        )
      }
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  // MARK: - Status
  public struct UserStatus: Sendable, Hashable {
    public let id: String
    public let name: String
    public let title: String?
    public let flair: String?
    public let online: Bool?
    public let playing: Bool?
    public let streaming: Bool?
    public let patron: Bool?
  }

  public func getUsersStatus(ids: [String], withSignal: Bool? = nil, withGameIds: Bool? = nil, withGameMetas: Bool? = nil) async throws -> [UserStatus] {
    let resp = try await underlyingClient.apiUsersStatus(query: .init(ids: ids.joined(separator: ","), withSignal: withSignal, withGameIds: withGameIds, withGameMetas: withGameMetas))
    switch resp {
    case .ok(let ok):
      let rows = try ok.body.json
      return rows.map { r in
        UserStatus(id: r.id, name: r.name, title: r.title?.rawValue, flair: r.flair, online: r.online, playing: r.playing, streaming: r.streaming, patron: r.patron)
      }
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  // MARK: - Notes & Inbox
  public struct UserNotePublic: Sendable, Hashable { public let from: String?; public let to: String?; public let text: String?; public let date: Date? }

  public func getNotes(for username: String) async throws -> [UserNotePublic] {
    let resp = try await underlyingClient.readNote(path: .init(username: username))
    switch resp {
    case .ok(let ok):
      let rows = try ok.body.json
      return rows.map { n in
        UserNotePublic(from: n.from?.name, to: n.to?.name, text: n.text, date: toDate(ms: n.date))
      }
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  @discardableResult
  public func addNote(for username: String, text: String) async throws -> Bool {
    let body = Operations.writeNote.Input.Body.urlEncodedForm(.init(text: text))
    let resp = try await underlyingClient.writeNote(path: .init(username: username), body: body)
    switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  @discardableResult
  public func sendPrivateMessage(to username: String, text: String) async throws -> Bool {
    let body = Operations.inboxUsername.Input.Body.urlEncodedForm(.init(text: text))
    let resp = try await underlyingClient.inboxUsername(path: .init(username: username), body: body)
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - Follow/Block
  @discardableResult public func follow(username: String) async throws -> Bool { let resp = try await underlyingClient.followUser(path: .init(username: username)); switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) } }
  @discardableResult public func unfollow(username: String) async throws -> Bool { let resp = try await underlyingClient.unfollowUser(path: .init(username: username)); switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) } }
  @discardableResult public func block(username: String) async throws -> Bool { let resp = try await underlyingClient.blockUser(path: .init(username: username)); switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) } }
  @discardableResult public func unblock(username: String) async throws -> Bool { let resp = try await underlyingClient.unblockUser(path: .init(username: username)); switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) } }

  // MARK: - Following list (NDJSON)
  public func getMyFollowingNDJSON() async throws -> HTTPBody {
    let resp = try await underlyingClient.apiUserFollowing()
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_ndjson; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - Activity, Perf, Rating History
  public func getUserActivity(username: String) async throws -> HTTPBody {
    let resp = try await underlyingClient.apiUserActivity(path: .init(username: username))
    switch resp {
    case .ok(let ok):
      let data = try JSONEncoder().encode(try ok.body.json)
      return HTTPBody(data)
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  public typealias PerfStatPublic = OpenAPIRuntime.OpenAPIValueContainer
  public func getUserPerf(username: String, perfType: String) async throws -> PerfStatPublic {
    guard let perf = Components.Schemas.PerfType(rawValue: perfType) else { throw LichessClientError.parsingError(error: NSError(domain: "PerfType", code: 0)) }
    let resp = try await underlyingClient.apiUserPerf(path: .init(username: username, perf: perf))
    switch resp { case .ok(let ok): return try ok.body.json; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public typealias RatingHistoryPublic = OpenAPIRuntime.OpenAPIValueContainer
  public func getUserRatingHistory(username: String) async throws -> RatingHistoryPublic {
    let resp = try await underlyingClient.apiUserRatingHistory(path: .init(username: username))
    switch resp { case .ok(let ok): return try ok.body.json; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - Current game (PGN or JSON as HTTPBody)
  public enum CurrentGameFormat { case pgn, json }
  public func getUserCurrentGame(username: String, format: CurrentGameFormat = .json, moves: Bool? = nil, pgnInJson: Bool? = nil, tags: Bool? = nil, clocks: Bool? = nil, evals: Bool? = nil, accuracy: Bool? = nil, opening: Bool? = nil, division: Bool? = nil, literate: Bool? = nil) async throws -> HTTPBody {
    let accept: [OpenAPIRuntime.AcceptHeaderContentType<Operations.apiUserCurrentGame.AcceptableContentType>] = format == .pgn ? [.init(contentType: .application_x_hyphen_chess_hyphen_pgn)] : [.init(contentType: .json)]
    let resp = try await underlyingClient.apiUserCurrentGame(
      path: .init(username: username),
      query: .init(moves: moves, pgnInJson: pgnInJson, tags: tags, clocks: clocks, evals: evals, accuracy: accuracy, opening: opening, division: division, literate: literate),
      headers: .init(accept: accept)
    )
    switch resp {
    case .ok(let ok):
      switch ok.body {
      case .application_x_hyphen_chess_hyphen_pgn(let b): return b
      case .json(let j):
        let data = try JSONEncoder().encode(j)
        return HTTPBody(data)
      }
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  // MARK: - Tournaments by user (NDJSON)
  public func getUserCreatedTournaments(username: String, nb: Int? = nil, status: Int? = nil) async throws -> HTTPBody {
    let statusPayload = status.flatMap { Operations.apiUserNameTournamentCreated.Input.Query.statusPayload(rawValue: $0) }
    let resp = try await underlyingClient.apiUserNameTournamentCreated(path: .init(username: username), query: .init(nb: nb, status: statusPayload))
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_ndjson; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func getUserPlayedTournaments(username: String, nb: Int? = nil) async throws -> HTTPBody {
    let resp = try await underlyingClient.apiUserNameTournamentPlayed(path: .init(username: username), query: .init(nb: nb))
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_ndjson; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }
}
