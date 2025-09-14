//
//  LichessClient+Puzzles.swift
//
//
//  Lightweight wrappers around Puzzles endpoints
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  public struct PuzzleGamePerf: Codable {
    public let key: String
    public let name: String
  }

  public struct PuzzleGamePlayer: Codable {
    public let id: String
    public let name: String
    public let rating: Int
    public let title: String?
    public let color: String
  }

  public struct PuzzleGame: Codable {
    public let id: String
    public let rated: Bool
    public let clock: String
    public let pgn: String
    public let perf: PuzzleGamePerf
    public let players: [PuzzleGamePlayer]
  }

  public struct Puzzle: Codable {
    public let id: String
    public let initialPly: Int
    public let plays: Int
    public let rating: Int
    public let solution: [String]
    public let themes: [String]
  }

  public struct PuzzleAndGame: Codable {
    public let game: PuzzleGame
    public let puzzle: Puzzle
  }

  private func convert(_ payload: Components.Schemas.PuzzleAndGame) -> PuzzleAndGame {
    let game = payload.game
    let puzzle = payload.puzzle

    let perf = PuzzleGamePerf(key: game.perf.key.rawValue, name: game.perf.name)
    let players: [PuzzleGamePlayer] = game.players.map { p in
      PuzzleGamePlayer(
        id: p.id,
        name: p.name,
        rating: p.rating,
        title: p.title?.rawValue,
        color: p.color
      )
    }

    let mappedGame = PuzzleGame(
      id: game.id,
      rated: game.rated,
      clock: game.clock,
      pgn: game.pgn,
      perf: perf,
      players: players
    )
    let mappedPuzzle = Puzzle(
      id: puzzle.id,
      initialPly: puzzle.initialPly,
      plays: puzzle.plays,
      rating: puzzle.rating,
      solution: puzzle.solution,
      themes: puzzle.themes
    )
    return PuzzleAndGame(game: mappedGame, puzzle: mappedPuzzle)
  }

  public func getDailyPuzzle() async throws -> PuzzleAndGame {
    let response = try await underlyingClient.apiPuzzleDaily()
    switch response {
    case .ok(let okResponse):
      let payload = try okResponse.body.json
      return convert(payload)
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func getPuzzle(id: String) async throws -> PuzzleAndGame {
    let response = try await underlyingClient.apiPuzzleId(path: .init(id: id))
    switch response {
    case .ok(let okResponse):
      let payload = try okResponse.body.json
      return convert(payload)
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func getNextPuzzle(angle: String? = nil) async throws -> PuzzleAndGame {
    let response = try await underlyingClient.apiPuzzleNext(query: .init(angle: angle))
    switch response {
    case .ok(let okResponse):
      let payload = try okResponse.body.json
      return convert(payload)
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  // MARK: - Activity (NDJSON)
  public func getPuzzleActivity(max: Int? = nil, before: Int? = nil) async throws -> HTTPBody {
    let resp = try await underlyingClient.apiPuzzleActivity(
      query: .init(max: max, before: before),
      headers: .init(accept: [.init(contentType: .application_x_hyphen_ndjson)])
    )
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_ndjson; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - Replay & Dashboard
  public struct PuzzleReplaySummary: Codable {
    public let days: Double
    public let theme: String
    public let total: Double
    public let remaining: [String]
    public let angleKey: String
    public let angleName: String
    public let angleDescription: String
  }

  public func getPuzzleReplay(days: Double, theme: String) async throws -> PuzzleReplaySummary? {
    let resp = try await underlyingClient.apiPuzzleReplay(path: .init(days: days, theme: theme))
    switch resp {
    case .ok(let ok):
      let j = try ok.body.json
      return PuzzleReplaySummary(
        days: j.replay.days,
        theme: j.replay.theme,
        total: j.replay.nb,
        remaining: j.replay.remaining,
        angleKey: j.angle.key,
        angleName: j.angle.name,
        angleDescription: j.angle.desc
      )
    case .notFound:
      return nil
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  public struct PuzzlePerformanceSummary: Codable { public let firstWins: Int; public let nb: Int; public let performance: Int; public let puzzleRatingAvg: Int; public let replayWins: Int }
  public struct PuzzleDashboardSummary: Codable {
    public let days: Int
    public let global: PuzzlePerformanceSummary
    public let themes: [String: PuzzlePerformanceSummary]
  }

  public func getPuzzleDashboard(days: Int) async throws -> PuzzleDashboardSummary {
    let resp = try await underlyingClient.apiPuzzleDashboard(path: .init(days: days))
    switch resp {
    case .ok(let ok):
      let j = try ok.body.json
      func mapPerf(_ p: Components.Schemas.PuzzlePerformance) -> PuzzlePerformanceSummary {
        .init(firstWins: p.firstWins, nb: p.nb, performance: p.performance, puzzleRatingAvg: p.puzzleRatingAvg, replayWins: p.replayWins)
      }
      var themes: [String: PuzzlePerformanceSummary] = [:]
      for (k, v) in j.themes.additionalProperties { themes[k] = mapPerf(v.results) }
      return PuzzleDashboardSummary(days: j.days, global: mapPerf(j.global), themes: themes)
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  // MARK: - Storm
  public struct StormHighs: Codable { public let allTime: Int; public let day: Int; public let month: Int; public let week: Int }
  public struct StormDay: Codable { public let id: String; public let combo: Int; public let errors: Int; public let highest: Int; public let moves: Int; public let runs: Int; public let score: Int; public let time: Int }
  public struct StormDashboardSummary: Codable { public let days: [StormDay]; public let high: StormHighs }

  public func getStormDashboard(username: String, lastDays: Int? = nil) async throws -> StormDashboardSummary {
    let resp = try await underlyingClient.apiStormDashboard(path: .init(username: username), query: .init(days: lastDays))
    switch resp {
    case .ok(let ok):
      let j = try ok.body.json
      let days = j.days.map { StormDay(id: $0._id, combo: $0.combo, errors: $0.errors, highest: $0.highest, moves: $0.moves, runs: $0.runs, score: $0.score, time: $0.time) }
      let h = j.high
      return StormDashboardSummary(days: days, high: .init(allTime: h.allTime, day: h.day, month: h.month, week: h.week))
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  // MARK: - Racer
  public struct PuzzleRacerInfo: Codable { public let id: String; public let url: String }
  public struct PuzzleRacePlayer: Codable { public let name: String; public let score: Int; public let id: String?; public let flair: String?; public let patron: Bool? }
  public struct PuzzleRaceResultsSummary: Codable { public let id: String; public let owner: String; public let players: [PuzzleRacePlayer]; public let finishesAt: Int; public let startsAt: Int }

  public func createRacer() async throws -> PuzzleRacerInfo {
    let resp = try await underlyingClient.racerPost()
    switch resp { case .ok(let ok): let j = try ok.body.json; return .init(id: j.id, url: j.url); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func getRacer(id: String) async throws -> PuzzleRaceResultsSummary? {
    let resp = try await underlyingClient.racerGet(path: .init(id: id))
    switch resp {
    case .ok(let ok):
      let j = try ok.body.json
      let players = j.players.map { PuzzleRacePlayer(name: $0.name, score: $0.score, id: $0.id, flair: $0.flair, patron: $0.patron) }
      return .init(id: j.id, owner: j.owner, players: players, finishesAt: j.finishesAt, startsAt: j.startsAt)
    case .notFound:
      return nil
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }
}
