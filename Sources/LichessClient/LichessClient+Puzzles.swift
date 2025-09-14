//
//  LichessClient+Puzzles.swift
//
//
//  Lightweight wrappers around Puzzles endpoints
//

import Foundation

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
}
