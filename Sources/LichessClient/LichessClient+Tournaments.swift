//
//  LichessClient+Tournaments.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: Arena models

  public struct ArenaTournamentSummary: Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let rated: Bool
    public let variantKey: String
    public let minutes: Int?
    public let secondsToStart: Int?
    public let nbPlayers: Int?
  }

  public struct ArenaTournamentsPage: Codable, Sendable, Hashable {
    public let created: [ArenaTournamentSummary]
    public let started: [ArenaTournamentSummary]
    public let finished: [ArenaTournamentSummary]
  }

  public struct ArenaClock: Codable, Sendable, Hashable { public let timeMinutes: Double; public let incrementSeconds: Int }

  public struct ArenaTournamentDetails: Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let rated: Bool
    public let variantKey: String
    public let minutes: Int
    public let clock: ArenaClock
    public let nbPlayers: Int?
    public let status: String?
  }

  // MARK: Arena helpers

  private func mapArenaSummary(_ t: Components.Schemas.ArenaTournament) -> ArenaTournamentSummary {
    ArenaTournamentSummary(
      id: t.id,
      name: t.fullName,
      rated: t.rated,
      variantKey: t.variant.key.rawValue,
      minutes: t.minutes,
      secondsToStart: t.secondsToStart,
      nbPlayers: t.nbPlayers
    )
  }

  private func mapArenaDetails(_ f: Components.Schemas.ArenaTournamentFull) -> ArenaTournamentDetails {
    let inc = Int(f.clock.increment)
    let time = Double(f.clock.limit)
    return ArenaTournamentDetails(
      id: f.id,
      name: f.fullName ?? "",
      rated: f.rated ?? false,
      variantKey: f.variant ?? "standard",
      minutes: Int(f.minutes ?? 0),
      clock: ArenaClock(timeMinutes: time, incrementSeconds: inc),
      nbPlayers: Int(f.nbPlayers),
      status: (f.isFinished == true ? "finished" : ((f.secondsToStart ?? 0) > 0 ? "created" : "started"))
    )
  }

  // MARK: Arena wrappers

  /// Get recently active and finished Arena tournaments (schedule).
  public func getCurrentTournaments() async throws -> ArenaTournamentsPage {
    let resp = try await underlyingClient.apiTournament()
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      return ArenaTournamentsPage(
        created: (payload.created ?? []).map(mapArenaSummary),
        started: (payload.started ?? []).map(mapArenaSummary),
        finished: (payload.finished ?? []).map(mapArenaSummary)
      )
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  /// Get detailed info about an Arena tournament (duels, standings, etc.).
  public func getArenaTournament(id: String, page: Int? = nil) async throws -> ArenaTournamentDetails {
    let resp = try await underlyingClient.tournament(path: .init(id: id), query: .init(page: page.map(Double.init)))
    switch resp {
    case .ok(let ok):
      let full = try ok.body.json
      return mapArenaDetails(full)
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  public struct ArenaCreateOptions: Sendable, Hashable {
    public var name: String?
    public var clockTimeMinutes: Double
    public var clockIncrementSeconds: Int
    public var minutes: Int
    public var rated: Bool
    public var variantKey: String? // standard, blitz, etc.
    public var startsAt: Int64?
    public init(name: String? = nil, clockTimeMinutes: Double, clockIncrementSeconds: Int, minutes: Int, rated: Bool = true, variantKey: String? = nil, startsAt: Int64? = nil) {
      self.name = name; self.clockTimeMinutes = clockTimeMinutes; self.clockIncrementSeconds = clockIncrementSeconds; self.minutes = minutes; self.rated = rated; self.variantKey = variantKey; self.startsAt = startsAt
    }
  }

  /// Create a new Arena tournament.
  public func createArenaTournament(_ opts: ArenaCreateOptions) async throws -> ArenaTournamentDetails {
    guard let inc = Operations.apiTournamentPost.Input.Body.urlEncodedFormPayload.clockIncrementPayload(rawValue: opts.clockIncrementSeconds) else {
      throw LichessClientError.parsingError(error: NSError(domain: "ArenaCreate", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unsupported clock increment: \(opts.clockIncrementSeconds)"]))
    }
    guard let mins = Operations.apiTournamentPost.Input.Body.urlEncodedFormPayload.minutesPayload(rawValue: opts.minutes) else {
      throw LichessClientError.parsingError(error: NSError(domain: "ArenaCreate", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unsupported minutes value: \(opts.minutes)"]))
    }
    var body = Operations.apiTournamentPost.Input.Body.urlEncodedFormPayload(
      name: opts.name,
      clockTime: opts.clockTimeMinutes,
      clockIncrement: inc,
      minutes: mins
    )
    body.rated = opts.rated
    body.variant = opts.variantKey.flatMap { Components.Schemas.VariantKey(rawValue: $0) }
    body.startDate = opts.startsAt
    let resp = try await underlyingClient.apiTournamentPost(body: .urlEncodedForm(body))
    switch resp {
    case .ok(let ok): return mapArenaDetails(try ok.body.json)
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "ArenaCreate", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  /// Update basic attributes of an Arena tournament.
  public func updateArenaTournament(id: String, minutes: Int? = nil, clockTimeMinutes: Double? = nil, clockIncrementSeconds: Int? = nil, rated: Bool? = nil) async throws -> ArenaTournamentDetails {
    var payload = Operations.apiTournamentUpdate.Input.Body.urlEncodedFormPayload(
      clockTime: clockTimeMinutes ?? 5.0,
      clockIncrement: ._0,
      minutes: ._20
    )
    if let m = minutes, let pm = Operations.apiTournamentUpdate.Input.Body.urlEncodedFormPayload.minutesPayload(rawValue: m) { payload.minutes = pm }
    if let ct = clockTimeMinutes { payload.clockTime = ct }
    if let inc = clockIncrementSeconds, let pinc = Operations.apiTournamentUpdate.Input.Body.urlEncodedFormPayload.clockIncrementPayload(rawValue: inc) { payload.clockIncrement = pinc }
    if let r = rated { payload.rated = r }
    let resp = try await underlyingClient.apiTournamentUpdate(path: .init(id: id), body: .urlEncodedForm(payload))
    switch resp { case .ok(let ok): return mapArenaDetails(try ok.body.json); case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Join an Arena tournament (optionally with password or team).
  public func joinArenaTournament(id: String, password: String? = nil, teamId: String? = nil) async throws -> Bool {
    let body: Operations.apiTournamentJoin.Input.Body? =
      (password != nil || teamId != nil) ? .urlEncodedForm(.init(password: password, team: teamId)) : nil
    let resp = try await underlyingClient.apiTournamentJoin(path: .init(id: id), body: body)
    switch resp { case .ok: return true; case .badRequest(let bad): if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "ArenaJoin", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }; throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Withdraw or pause from an Arena tournament.
  public func withdrawArenaTournament(id: String) async throws -> Bool {
    let resp = try await underlyingClient.apiTournamentWithdraw(path: .init(id: id))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Terminate an Arena tournament.
  public func terminateArenaTournament(id: String) async throws -> Bool {
    let resp = try await underlyingClient.apiTournamentTerminate(path: .init(id: id))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Update a team battle (teams and leaders).
  public func updateTeamBattle(id: String, teamIds: [String], leadersPerTeam: Int) async throws -> ArenaTournamentDetails {
    let body = Operations.apiTournamentTeamBattlePost.Input.Body.urlEncodedFormPayload(teams: teamIds.joined(separator: ","), nbLeaders: leadersPerTeam)
    let resp = try await underlyingClient.apiTournamentTeamBattlePost(path: .init(id: id), body: .urlEncodedForm(body))
    switch resp { case .ok(let ok): return mapArenaDetails(try ok.body.json); case .badRequest(let bad): if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "TeamBattle", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }; throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Add time to a live game clock (requires permission).
  public func addTimeToGame(gameId: String, seconds: Int) async throws -> Bool {
    let resp = try await underlyingClient.roundAddTime(path: .init(gameId: gameId, seconds: Double(seconds)))
    switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }
  public enum ExportFormat {
    case pgn
    case ndjson
  }

  // MARK: Arena tournaments

  public func exportTournamentGames(
    id: String,
    player: String? = nil,
    format: ExportFormat = .pgn,
    moves: Bool? = nil,
    pgnInJson: Bool? = nil,
    tags: Bool? = nil,
    clocks: Bool? = nil,
    evals: Bool? = nil,
    accuracy: Bool? = nil,
    opening: Bool? = nil,
    division: Bool? = nil
  ) async throws -> HTTPBody {
    let response = try await underlyingClient.gamesByTournament(
      path: .init(id: id),
      query: .init(
        player: player,
        moves: moves,
        pgnInJson: pgnInJson,
        tags: tags,
        clocks: clocks,
        evals: evals,
        accuracy: accuracy,
        opening: opening,
        division: division
      )
    )
    switch response {
    case .ok(let ok):
      switch ok.body {
      case .application_x_hyphen_chess_hyphen_pgn(let body):
        return body
      case .application_x_hyphen_ndjson(let body):
        return body
      }
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func streamTournamentResults(
    id: String,
    nb: Int? = nil,
    sheet: Bool? = nil
  ) async throws -> HTTPBody {
    let response = try await underlyingClient.resultsByTournament(
      path: .init(id: id),
      query: .init(nb: nb, sheet: sheet)
    )
    switch response {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  // MARK: Swiss tournaments

  public func exportSwissGames(
    id: String,
    player: String? = nil,
    format: ExportFormat = .pgn,
    moves: Bool? = nil,
    pgnInJson: Bool? = nil,
    tags: Bool? = nil,
    clocks: Bool? = nil,
    evals: Bool? = nil,
    accuracy: Bool? = nil,
    opening: Bool? = nil,
    division: Bool? = nil
  ) async throws -> HTTPBody {
    let response = try await underlyingClient.gamesBySwiss(
      path: .init(id: id),
      query: .init(
        player: player,
        moves: moves,
        pgnInJson: pgnInJson,
        tags: tags,
        clocks: clocks,
        evals: evals,
        accuracy: accuracy,
        opening: opening,
        division: division
      )
    )
    switch response {
    case .ok(let ok):
      switch ok.body {
      case .application_x_hyphen_chess_hyphen_pgn(let body):
        return body
      case .application_x_hyphen_ndjson(let body):
        return body
      }
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func streamSwissResults(
    id: String,
    nb: Int? = nil,
    sheet: Bool? = nil
  ) async throws -> HTTPBody {
    let response = try await underlyingClient.resultsBySwiss(path: .init(id: id), query: .init(nb: nb))
    switch response {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }
}
