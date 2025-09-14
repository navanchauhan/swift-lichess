//
//  LichessClient+Broadcasts.swift
//
//
//  Created by Navan Chauhan on 4/24/24.
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: - Public models

  public struct BroadcastSummary: Codable, Sendable {
    public let tour: Tournament
    public let round: Round?
    public let groupName: String?
  }

  public struct BroadcastPastPage: Codable, Sendable {
    public let currentPage: Int
    public let maxPerPage: Int
    public let results: [BroadcastSummary]
    public let previousPage: Int?
    public let nextPage: Int?
  }

  public struct BroadcastTopResult: Codable, Sendable {
    public let active: [BroadcastSummary]
    public let upcoming: [BroadcastSummary]
    public let past: BroadcastPastPage?
  }

  public struct BroadcastWithRoundsPublic: Codable, Sendable {
    public let tour: Tournament
    public let rounds: [Round]
    public let defaultRoundId: String?
    public let groupName: String?
  }

  public struct BroadcastGamePlayer: Codable, Sendable {
    public let name: String?
    public let title: String?
    public let rating: Int?
    public let fideId: Int?
    public let fed: String?
    public let clock: Int?
  }

  public struct BroadcastRoundGamePublic: Codable, Sendable {
    public let id: String
    public let name: String
    public let fen: String?
    public let players: [BroadcastGamePlayer]
    public let lastMove: String?
    public let check: String?
    public let thinkTime: Int?
    public let status: String?
  }

  public struct BroadcastRoundDetails: Codable, Sendable {
    public let round: Round
    public let tour: Tournament
    public let studyWriteable: Bool?
    public let games: [BroadcastRoundGamePublic]
    public let groupName: String?
  }

  public struct BroadcastPlayerTiebreakPublic: Codable, Sendable {
    public let code: String?
    public let description: String?
    public let points: Double?
  }

  public struct BroadcastPlayerEntryPublic: Codable, Sendable {
    public let name: String?
    public let score: Double?
    public let played: Int?
    public let rating: Int?
    public let ratingDiff: Int?
    public let performance: Int?
    public let title: String?
    public let fideId: Int?
    public let fed: String?
    public let tiebreaks: [BroadcastPlayerTiebreakPublic]?
    public let rank: Int?
  }

  public struct BroadcastPGNPushResult: Codable, Sendable {
    public let tags: [String: String]
    public let moves: Int?
    public let error: String?
  }
  public struct TournamentResponse: Codable, Identifiable {
    public let id: String
    public let tour: Tournament
    public let rounds: [Round]

    public init(from decoder: Decoder) throws {
      let container: KeyedDecodingContainer<LichessClient.TournamentResponse.CodingKeys> =
        try decoder.container(keyedBy: LichessClient.TournamentResponse.CodingKeys.self)
      self.tour = try container.decode(
        LichessClient.Tournament.self, forKey: LichessClient.TournamentResponse.CodingKeys.tour)
      self.rounds = try container.decode(
        [LichessClient.Round].self, forKey: LichessClient.TournamentResponse.CodingKeys.rounds)
      self.id = tour.id
    }
  }

  public struct Tournament: Codable, Sendable {
    public let id: String
    public let name: String
    public let slug: String
    public let description: String?
    public let markup: String?
    public let url: String?
  }

  public struct Round: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let slug: String
    // Lichess returns milliseconds since epoch for startsAt; decode as Int64
    public let startsAt: Int64
    public let finished: Bool?
    public let ongoing: Bool?

  }

  public struct Player: Codable {
    public let userId: String
    public let name: String
    public let color: String
  }

  // MARK: - Helpers (mapping generated payloads)

  private func mapTour(_ t: Components.Schemas.BroadcastTour) -> Tournament {
    Tournament(
      id: t.id,
      name: t.name,
      slug: t.slug,
      description: t.description,
      markup: nil,
      url: t.url
    )
  }

  private func mapRoundInfo(_ r: Components.Schemas.BroadcastRoundInfo) -> Round {
    Round(
      id: r.id,
      name: r.name,
      slug: r.slug,
      startsAt: r.startsAt ?? 0,
      finished: r.finished,
      ongoing: r.ongoing
    )
  }

  private func groupName(_ g: Components.Schemas.BroadcastGroup?) -> String? {
    g?.name
  }

  private func mapSummary(_ s: Components.Schemas.BroadcastWithLastRound) -> BroadcastSummary {
    let tour = s.tour.map(mapTour)
    let round = s.round.map(mapRoundInfo)
    return BroadcastSummary(tour: tour!, round: round, groupName: s.group)
  }

  public func broadcastIndex(nb: Int = 20) async throws -> AsyncThrowingMapSequence<
    JSONLinesDeserializationSequence<HTTPBody>, LichessClient.TournamentResponse
  > {
    let response = try await underlyingClient.broadcastsOfficial(query: .init(nb: nb))
    switch response {
    case .ok(let okResponse):
      let tournaments = try okResponse.body.application_x_hyphen_ndjson.asDecodedJSONLines(
        of: TournamentResponse.self)
      return tournaments
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func broadcastRound(
    broadcastTournamentSlug: String = "-", broadcastRoundSlug: String = "-",
    broadcastRoundId: String
  ) async throws -> BroadcastRoundDetails {
    let response = try await underlyingClient.broadcastRoundGet(
      path: .init(
        broadcastTournamentSlug: broadcastTournamentSlug,
        broadcastRoundSlug: broadcastRoundSlug,
        broadcastRoundId: broadcastRoundId
      ))
    switch response {
    case .ok(let okResponse):
      let payload = try okResponse.body.json
      let round = mapRoundInfo(payload.round)
      let tour = mapTour(payload.tour)
      let writeable = payload.study.writeable
      let games: [BroadcastRoundGamePublic] = payload.games.map { g in
        let players = (g.players ?? []).map { p in
          BroadcastGamePlayer(
            name: p.name,
            title: p.title?.rawValue,
            rating: p.rating,
            fideId: p.fideId,
            fed: p.fed,
            clock: p.clock
          )
        }
        return BroadcastRoundGamePublic(
          id: g.id,
          name: g.name,
          fen: g.fen,
          players: players,
          lastMove: g.lastMove,
          check: g.check?.rawValue,
          thinkTime: g.thinkTime,
          status: g.status?.rawValue
        )
      }
      return BroadcastRoundDetails(
        round: round,
        tour: tour,
        studyWriteable: writeable,
        games: games,
        groupName: groupName(payload.group)
      )
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func getBroadcastRoundPGN(broadcastRoundId: String) async throws -> HTTPBody {
    let response = try await underlyingClient.broadcastRoundPgn(
      path: .init(
        broadcastRoundId: broadcastRoundId
      ))

    switch response {
    case .ok(let okResponse):
      return try okResponse.body.application_x_hyphen_chess_hyphen_pgn
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func broadcastStreamRoundPgn(broadcastRoundId: String) async throws -> HTTPBody {
    let response = try await underlyingClient.broadcastStreamRoundPgn(
      path: .init(broadcastRoundId: broadcastRoundId))
    switch response {
    case .ok(let okResponse):
      return try okResponse.body.application_x_hyphen_chess_hyphen_pgn
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  // MARK: - Additional Broadcasts coverage

  /// Get paginated top broadcast previews (active, upcoming, and past pages).
  public func getTopBroadcasts(page: Int? = nil, html: Bool? = nil) async throws -> BroadcastTopResult {
    let resp = try await underlyingClient.broadcastsTop(
      query: .init(page: page, html: html)
    )
    switch resp {
    case .ok(let ok):
      let top = try ok.body.json
      let active = (top.active ?? []).map(mapSummary)
      let upcoming = (top.upcoming ?? []).map(mapSummary)
      let past: BroadcastPastPage? = {
        guard let p = top.past else { return nil }
        let results = (p.currentPageResults ?? []).map(mapSummary)
        return BroadcastPastPage(
          currentPage: p.currentPage ?? 1,
          maxPerPage: p.maxPerPage ?? results.count,
          results: results,
          previousPage: p.previousPage.map(Int.init),
          nextPage: p.nextPage.map(Int.init)
        )
      }()
      return BroadcastTopResult(active: active, upcoming: upcoming, past: past)
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  /// Search broadcasts (paginated).
  public func searchBroadcasts(q: String, page: Int? = nil) async throws -> BroadcastPastPage {
    let resp = try await underlyingClient.broadcastsSearch(
      query: .init(page: page, q: q)
    )
    switch resp {
    case .ok(let ok):
      let p = try ok.body.json
      let results = p.currentPageResults.map(mapSummary)
      return BroadcastPastPage(
        currentPage: Int(p.currentPage),
        maxPerPage: Int(p.maxPerPage),
        results: results,
        previousPage: p.previousPage.map(Int.init),
        nextPage: p.nextPage.map(Int.init)
      )
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  /// Get broadcasts created by a specific user.
  public func getBroadcastsByUser(username: String) async throws -> [Tournament] {
    let resp = try await underlyingClient.broadcastsByUser(path: .init(username: username))
    switch resp {
    case .ok(let ok):
      let page = try ok.body.json
      return page.currentPageResults.map { mapTour($0.tour) }
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  /// Get a broadcast tournament with its rounds.
  public func getBroadcastTournament(id: String) async throws -> BroadcastWithRoundsPublic {
    let resp = try await underlyingClient.broadcastTourGet(path: .init(broadcastTournamentId: id))
    switch resp {
    case .ok(let ok):
      let v = try ok.body.json
      return BroadcastWithRoundsPublic(
        tour: mapTour(v.tour),
        rounds: v.rounds.map(mapRoundInfo),
        defaultRoundId: v.defaultRoundId,
        groupName: groupName(v.group)
      )
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  /// Get the list of players of a broadcast tournament, if available.
  public func getBroadcastPlayers(tournamentId: String) async throws -> [BroadcastPlayerEntryPublic] {
    let resp = try await underlyingClient.broadcastPlayersGet(path: .init(broadcastTournamentId: tournamentId))
    switch resp {
    case .ok(let ok):
      let list = try ok.body.json
      return list.map { p in
        BroadcastPlayerEntryPublic(
          name: p.name,
          score: p.score,
          played: p.played,
          rating: p.rating,
          ratingDiff: p.ratingDiff,
          performance: p.performance,
          title: p.title?.rawValue,
          fideId: p.fideId,
          fed: p.fed,
          tiebreaks: p.tiebreaks?.map { .init(code: $0.extendedCode?.rawValue, description: $0.description, points: $0.points) },
          rank: p.rank
        )
      }
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  /// Download all games of all rounds of a broadcast tournament in PGN format.
  public func getBroadcastAllRoundsPGN(tournamentId: String) async throws -> HTTPBody {
    let resp = try await underlyingClient.broadcastAllRoundsPgn(path: .init(broadcastTournamentId: tournamentId))
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_chess_hyphen_pgn
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  /// Stream all broadcast rounds you are a member of (NDJSON).
  public func getMyBroadcastRounds(nb: Int? = nil) async throws -> HTTPBody {
    let resp = try await underlyingClient.broadcastMyRoundsGet(query: .init(nb: nb))
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  /// Push PGN lines to a broadcast round. Returns one result per game.
  public func pushBroadcastPGN(roundId: String, pgn: String) async throws -> [BroadcastPGNPushResult] {
    let resp = try await underlyingClient.broadcastPush(
      path: .init(broadcastRoundId: roundId),
      body: .plainText(.init(pgn))
    )
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      return payload.games.map { g in
        BroadcastPGNPushResult(
          tags: g.tags.additionalProperties,
          moves: g.moves,
          error: g.error
        )
      }
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBroadcastPush", code: 400, userInfo: [NSLocalizedDescriptionKey: msg]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  /// Reset a broadcast round by removing any games and returning it to its initial state.
  public func resetBroadcastRound(roundId: String) async throws -> Bool {
    let resp = try await underlyingClient.broadcastRoundReset(path: .init(broadcastRoundId: roundId))
    switch resp {
    case .ok: return true
    case .undocumented(let code, _):
      switch code {
      case 401: throw LichessClientError.unauthorized
      case 403: throw LichessClientError.forbidden
      case 404: throw LichessClientError.notFound
      case 429: throw LichessClientError.tooManyRequests(retryAfterSeconds: nil)
      default: throw LichessClientError.httpStatus(statusCode: code)
      }
    }
  }

  // MARK: - Admin/write helpers (tournament/round create & update)

  public struct BroadcastTournamentOptions: Sendable, Hashable {
    public var format: String?
    public var location: String?
    public var timeControl: String?
    public var fideTimeControl: String? // standard|rapid|blitz
    public var timeZone: String?
    public var players: String?
    public var website: String?
    public var standings: String?
    public var descriptionMarkdown: String?
    public var showScores: Bool?
    public var showRatingDiffs: Bool?
    public var teamTable: Bool?
    public var visibility: String? // public|unlisted|private
    public var playerOverrides: String?
    public var teams: String?
    public init() {}
  }

  public func createBroadcastTournament(name: String, options: BroadcastTournamentOptions = .init()) async throws -> BroadcastWithRoundsPublic {
    let body = Components.Schemas.BroadcastForm(
      name: name,
      info_period_format: options.format,
      info_period_location: options.location,
      info_period_tc: options.timeControl,
      info_period_fideTc: options.fideTimeControl.flatMap { Components.Schemas.BroadcastForm.info_period_fideTcPayload(rawValue: $0) },
      info_period_timeZone: options.timeZone,
      info_period_players: options.players,
      info_period_website: options.website,
      info_period_standings: options.standings,
      markdown: options.descriptionMarkdown,
      showScores: options.showScores,
      showRatingDiffs: options.showRatingDiffs,
      teamTable: options.teamTable,
      visibility: options.visibility.flatMap { Components.Schemas.BroadcastForm.visibilityPayload(rawValue: $0) },
      players: options.playerOverrides,
      teams: options.teams,
      tier: nil,
      tiebreaks_lbrack__rbrack_: nil
    )
    let resp = try await underlyingClient.broadcastTourCreate(body: .urlEncodedForm(body))
    switch resp {
    case .ok(let ok):
      let v = try ok.body.json
      return BroadcastWithRoundsPublic(
        tour: mapTour(v.tour),
        rounds: v.rounds.map(mapRoundInfo),
        defaultRoundId: v.defaultRoundId,
        groupName: groupName(v.group)
      )
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBroadcastTourCreate", code: 400, userInfo: [NSLocalizedDescriptionKey: msg]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  public func updateBroadcastTournament(id: String, options: BroadcastTournamentOptions) async throws -> Bool {
    let body = Components.Schemas.BroadcastForm(
      name: "", // name is required by the API form; set empty to keep unchanged
      info_period_format: options.format,
      info_period_location: options.location,
      info_period_tc: options.timeControl,
      info_period_fideTc: options.fideTimeControl.flatMap { Components.Schemas.BroadcastForm.info_period_fideTcPayload(rawValue: $0) },
      info_period_timeZone: options.timeZone,
      info_period_players: options.players,
      info_period_website: options.website,
      info_period_standings: options.standings,
      markdown: options.descriptionMarkdown,
      showScores: options.showScores,
      showRatingDiffs: options.showRatingDiffs,
      teamTable: options.teamTable,
      visibility: options.visibility.flatMap { Components.Schemas.BroadcastForm.visibilityPayload(rawValue: $0) },
      players: options.playerOverrides,
      teams: options.teams,
      tier: nil,
      tiebreaks_lbrack__rbrack_: nil
    )
    let resp = try await underlyingClient.broadcastTourUpdate(
      path: .init(broadcastTournamentId: id),
      body: .urlEncodedForm(body)
    )
    switch resp {
    case .ok: return true
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBroadcastTourUpdate", code: 400, userInfo: [NSLocalizedDescriptionKey: msg]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  public enum BroadcastRoundSource: Sendable, Hashable {
    case manual(name: String)
    case syncUrl(name: String, url: String, onlyRound: Int? = nil, slices: String? = nil)
    case syncUrls(name: String, urls: String, onlyRound: Int? = nil, slices: String? = nil)
    case syncIds(name: String, ids: String)
    case syncUsers(name: String, users: String)
  }

  public struct BroadcastRoundOptions: Sendable, Hashable {
    public var startsAtMS: Int64?
    public var startsAfterPrevious: Bool?
    public var delaySeconds: Int?
    public var status: String? // live/upcoming/finished (admin)
    public var rated: Bool?
    public var customPointsWhiteWin: Double?
    public var customPointsWhiteDraw: Double?
    public var customPointsBlackWin: Double?
    public var customPointsBlackDraw: Double?
    public init() {}
  }

  public func createBroadcastRound(tournamentId: String, source: BroadcastRoundSource, options: BroadcastRoundOptions = .init()) async throws -> BroadcastRoundDetails {
    // Build Value1
    let v1: Components.Schemas.BroadcastRoundForm.Value1Payload = {
      switch source {
      case .manual(let name):
        return .case1(.init(name: name))
      case .syncUrl(let name, let url, let onlyRound, let slices):
        return .case2(.init(name: name, syncUrl: url, onlyRound: onlyRound, slices: slices))
      case .syncUrls(let name, let urls, let onlyRound, let slices):
        return .case3(.init(name: name, syncUrls: urls, onlyRound: onlyRound, slices: slices))
      case .syncIds(let name, let ids):
        return .case4(.init(name: name, syncIds: ids))
      case .syncUsers(let name, let users):
        return .case5(.init(name: name, syncUsers: users))
      }
    }()
    // Build Value2
    let v2 = Components.Schemas.BroadcastRoundForm.Value2Payload(
      startsAt: options.startsAtMS,
      startsAfterPrevious: options.startsAfterPrevious,
      delay: options.delaySeconds,
      status: options.status.flatMap { Components.Schemas.BroadcastRoundForm.Value2Payload.statusPayload(rawValue: $0) },
      rated: options.rated,
      customScoring_period_white_period_win: options.customPointsWhiteWin,
      customScoring_period_white_period_draw: options.customPointsWhiteDraw,
      customScoring_period_black_period_win: options.customPointsBlackWin,
      customScoring_period_black_period_draw: options.customPointsBlackDraw,
      period: nil
    )
    let body: Operations.broadcastRoundCreate.Input.Body = .urlEncodedForm(.init(value1: v1, value2: v2))
    let resp = try await underlyingClient.broadcastRoundCreate(
      path: .init(broadcastTournamentId: tournamentId),
      body: body
    )
    switch resp {
    case .ok(let ok):
      let created = try ok.body.json
      let details = Components.Schemas.BroadcastRound(
        round: created.round,
        tour: created.tour,
        study: created.study,
        games: [],
        group: nil
      )
      // Reuse mapping for consistency
      let mapped = BroadcastRoundDetails(
        round: mapRoundInfo(details.round),
        tour: mapTour(details.tour),
        studyWriteable: details.study.writeable,
        games: [],
        groupName: nil
      )
      return mapped
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBroadcastRoundCreate", code: 400, userInfo: [NSLocalizedDescriptionKey: msg]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }

  public func updateBroadcastRound(roundId: String, source: BroadcastRoundSource, options: BroadcastRoundOptions = .init()) async throws -> BroadcastRoundDetails {
    let v1: Components.Schemas.BroadcastRoundForm.Value1Payload = {
      switch source {
      case .manual(let name): return .case1(.init(name: name))
      case .syncUrl(let name, let url, let onlyRound, let slices): return .case2(.init(name: name, syncUrl: url, onlyRound: onlyRound, slices: slices))
      case .syncUrls(let name, let urls, let onlyRound, let slices): return .case3(.init(name: name, syncUrls: urls, onlyRound: onlyRound, slices: slices))
      case .syncIds(let name, let ids): return .case4(.init(name: name, syncIds: ids))
      case .syncUsers(let name, let users): return .case5(.init(name: name, syncUsers: users))
      }
    }()
    let v2 = Components.Schemas.BroadcastRoundForm.Value2Payload(
      startsAt: options.startsAtMS,
      startsAfterPrevious: options.startsAfterPrevious,
      delay: options.delaySeconds,
      status: options.status.flatMap { Components.Schemas.BroadcastRoundForm.Value2Payload.statusPayload(rawValue: $0) },
      rated: options.rated,
      customScoring_period_white_period_win: options.customPointsWhiteWin,
      customScoring_period_white_period_draw: options.customPointsWhiteDraw,
      customScoring_period_black_period_win: options.customPointsBlackWin,
      customScoring_period_black_period_draw: options.customPointsBlackDraw,
      period: nil
    )
    let resp = try await underlyingClient.broadcastRoundUpdate(
      path: .init(broadcastRoundId: roundId),
      body: .urlEncodedForm(.init(value1: v1, value2: v2))
    )
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      let round = mapRoundInfo(payload.round)
      let tour = mapTour(payload.tour)
      let writeable = payload.study.writeable
      let games: [BroadcastRoundGamePublic] = payload.games.map { g in
        let players = (g.players ?? []).map { p in
          BroadcastGamePlayer(name: p.name, title: p.title?.rawValue, rating: p.rating, fideId: p.fideId, fed: p.fed, clock: p.clock)
        }
        return BroadcastRoundGamePublic(id: g.id, name: g.name, fen: g.fen, players: players, lastMove: g.lastMove, check: g.check?.rawValue, thinkTime: g.thinkTime, status: g.status?.rawValue)
      }
      return BroadcastRoundDetails(round: round, tour: tour, studyWriteable: writeable, games: games, groupName: groupName(payload.group))
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBroadcastRoundUpdate", code: 400, userInfo: [NSLocalizedDescriptionKey: msg]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let code, _):
      throw LichessClientError.undocumentedResponse(statusCode: code)
    }
  }
}
