//
//  LichessClient+Teams.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: Models

  public struct TeamUser: Sendable, Hashable {
    public let id: String
    public let name: String
    public let title: String?
    public let flair: String?
    public let patron: Bool?
  }

  public struct TeamInfo: Sendable, Hashable {
    public let id: String
    public let name: String
    public let description: String?
    public let flair: String?
    public let leader: TeamUser?
    public let leaders: [TeamUser]
    public let nbMembers: Int?
    public let open: Bool?
    public let joined: Bool?
    public let requested: Bool?
  }

  public struct TeamPage: Sendable, Hashable {
    public let currentPage: Int
    public let maxPerPage: Int
    public let results: [TeamInfo]
    public let previousPage: Int?
    public let nextPage: Int?
    public let nbResults: Int
    public let nbPages: Int
  }

  public struct TeamJoinRequest: Sendable, Hashable {
    public struct Request: Sendable, Hashable {
      public let teamId: String
      public let userId: String
      public let date: Date
      public let message: String?
    }
    public struct User: Sendable, Hashable {
      public let id: String
      public let username: String
      public let title: String?
      public let flair: String?
      public let patron: Bool?
      public let verified: Bool?
    }
    public let request: Request
    public let user: User
  }

  public struct TeamBattleStandings: Sendable, Hashable {
    public struct Entry: Sendable, Hashable {
      public struct TopPlayer: Sendable, Hashable { public let id: String; public let name: String; public let title: String?; public let flair: String?; public let patron: Bool?; public let score: Int? }
      public let rank: Int
      public let teamId: String
      public let score: Int
      public let players: [TopPlayer]
    }
    public let tournamentId: String
    public let teams: [Entry]
  }

  // MARK: Helpers (mapping)

  private func mapLightUser(_ u: Components.Schemas.LightUser?) -> TeamUser? {
    guard let u else { return nil }
    return TeamUser(id: u.id, name: u.name, title: u.title?.rawValue, flair: u.flair, patron: u.patron)
  }

  private func mapLightUsers(_ list: [Components.Schemas.LightUser]?) -> [TeamUser] {
    (list ?? []).map { TeamUser(id: $0.id, name: $0.name, title: $0.title?.rawValue, flair: $0.flair, patron: $0.patron) }
  }

  private func mapTeam(_ t: Components.Schemas.Team) -> TeamInfo {
    TeamInfo(
      id: t.id,
      name: t.name,
      description: t.description,
      flair: t.flair,
      leader: mapLightUser(t.leader),
      leaders: mapLightUsers(t.leaders),
      nbMembers: t.nbMembers,
      open: t.open,
      joined: t.joined,
      requested: t.requested
    )
  }

  private func mapTeamPage(_ p: Components.Schemas.TeamPaginatorJson) -> TeamPage {
    TeamPage(
      currentPage: Int(p.currentPage),
      maxPerPage: Int(p.maxPerPage),
      results: p.currentPageResults.map(mapTeam),
      previousPage: p.previousPage.map { Int($0) },
      nextPage: p.nextPage.map { Int($0) },
      nbResults: Int(p.nbResults),
      nbPages: Int(p.nbPages)
    )
  }

  // MARK: Queries (JSON)

  /// Get public info about a team.
  public func getTeam(id: String) async throws -> TeamInfo {
    let resp = try await underlyingClient.teamShow(path: .init(teamId: id))
    switch resp {
    case .ok(let ok):
      let team = try ok.body.json
      return mapTeam(team)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Get popular teams (paginated).
  public func getPopularTeams(page: Int? = nil) async throws -> TeamPage {
    let resp = try await underlyingClient.teamAll(query: .init(page: page.map(Double.init)))
    switch resp {
    case .ok(let ok):
      return mapTeamPage(try ok.body.json)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Search teams by text, with pagination.
  public func searchTeams(text: String, page: Int? = nil) async throws -> TeamPage {
    let resp = try await underlyingClient.teamSearch(query: .init(text: text, page: page.map(Double.init)))
    switch resp {
    case .ok(let ok):
      return mapTeamPage(try ok.body.json)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// List the teams a user is a member of.
  public func getTeams(of username: String) async throws -> [TeamInfo] {
    let resp = try await underlyingClient.teamOfUsername(path: .init(username: username))
    switch resp {
    case .ok(let ok):
      return try ok.body.json.map(mapTeam)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Get team battle standings for a tournament.
  public func getTeamBattleStandings(tournamentId: String) async throws -> TeamBattleStandings {
    let resp = try await underlyingClient.teamsByTournament(path: .init(id: tournamentId))
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      let entries: [TeamBattleStandings.Entry] = payload.teams.map { e in
        let tops: [TeamBattleStandings.Entry.TopPlayer] = e.players.map { p in
          TeamBattleStandings.Entry.TopPlayer(
            id: p.user.id,
            name: p.user.name,
            title: p.user.title?.rawValue,
            flair: p.user.flair,
            patron: p.user.patron,
            score: p.score.map { Int($0) }
          )
        }
        return .init(
          rank: Int(e.rank),
          teamId: e.id,
          score: Int(e.score),
          players: tops
        )
      }
      return TeamBattleStandings(tournamentId: payload.id, teams: entries)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Get pending (or declined) join requests for a team.
  public func getTeamJoinRequests(teamId: String, declined: Bool? = nil) async throws -> [TeamJoinRequest] {
    let resp = try await underlyingClient.teamRequests(path: .init(teamId: teamId), query: .init(declined: declined))
    switch resp {
    case .ok(let ok):
      return try ok.body.json.map { item in
        let r = item.request
        let u = item.user
        let request = TeamJoinRequest.Request(
          teamId: r.teamId,
          userId: r.userId,
          date: Date(timeIntervalSince1970: r.date / 1000.0),
          message: r.message
        )
        let user = TeamJoinRequest.User(
          id: u.id,
          username: u.username,
          title: u.title?.rawValue,
          flair: u.flair,
          patron: u.patron,
          verified: u.verified
        )
        return TeamJoinRequest(request: request, user: user)
      }
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: Commands (JSON)

  /// Request to join a team. Provide `message` for moderated teams and `password` if required.
  public func joinTeam(teamId: String, message: String? = nil, password: String? = nil) async throws -> Bool {
    let body = Operations.teamIdJoin.Input.Body.urlEncodedForm(.init(message: message, password: password))
    let resp = try await underlyingClient.teamIdJoin(path: .init(teamId: teamId), body: body)
    switch resp {
    case .ok(let ok):
      return (try? ok.body.json.ok) ?? true
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Leave a team.
  public func leaveTeam(teamId: String) async throws -> Bool {
    let resp = try await underlyingClient.teamIdQuit(path: .init(teamId: teamId))
    switch resp {
    case .ok(let ok):
      return (try? ok.body.json.ok) ?? true
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Kick a user from a team you manage.
  public func kickFromTeam(teamId: String, userId: String) async throws -> Bool {
    let resp = try await underlyingClient.teamIdKickUserId(path: .init(teamId: teamId, userId: userId))
    switch resp {
    case .ok(let ok):
      return (try? ok.body.json.ok) ?? true
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Accept a pending join request.
  public func acceptJoinRequest(teamId: String, userId: String) async throws -> Bool {
    let resp = try await underlyingClient.teamRequestAccept(path: .init(teamId: teamId, userId: userId))
    switch resp {
    case .ok(let ok):
      return (try? ok.body.json.ok) ?? true
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Decline a pending join request.
  public func declineJoinRequest(teamId: String, userId: String) async throws -> Bool {
    let resp = try await underlyingClient.teamRequestDecline(path: .init(teamId: teamId, userId: userId))
    switch resp {
    case .ok(let ok):
      return (try? ok.body.json.ok) ?? true
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Send a private message to all members of a team you manage.
  public func sendTeamMessage(teamId: String, message: String) async throws -> Bool {
    let body = Operations.teamIdPmAll.Input.Body.urlEncodedForm(.init(message: message))
    let resp = try await underlyingClient.teamIdPmAll(path: .init(teamId: teamId), body: body)
    switch resp {
    case .ok(let ok):
      return (try? ok.body.json.ok) ?? true
    case .badRequest(let bad):
      // Surfacing server-provided error string if any
      if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "LichessTeamPM", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: Streams (NDJSON)

  /// Stream Arena tournaments related to a team as NDJSON HTTPBody.
  /// Use `Streaming.ndjsonStream` to consume the stream.
  public func streamTeamArena(teamId: String, max: Int? = nil, createdBy: String? = nil, name: String? = nil) async throws -> HTTPBody {
    let query = Operations.apiTeamArena.Input.Query(max: max, status: nil, createdBy: createdBy, name: name)
    let resp = try await underlyingClient.apiTeamArena(path: .init(teamId: teamId), query: query)
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Stream Swiss tournaments of a team as NDJSON HTTPBody.
  /// Use `Streaming.ndjsonStream` to consume the stream.
  public func streamTeamSwiss(teamId: String, max: Int? = nil, createdBy: String? = nil, name: String? = nil) async throws -> HTTPBody {
    let query = Operations.apiTeamSwiss.Input.Query(max: max, status: nil, createdBy: createdBy, name: name)
    let resp = try await underlyingClient.apiTeamSwiss(path: .init(teamId: teamId), query: query)
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Stream team members as NDJSON HTTPBody. If `full == true`, the stream contains full `User` documents.
  public func streamTeamMembers(teamId: String, full: Bool? = nil) async throws -> HTTPBody {
    let resp = try await underlyingClient.teamIdUsers(path: .init(teamId: teamId), query: .init(full: full))
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}
