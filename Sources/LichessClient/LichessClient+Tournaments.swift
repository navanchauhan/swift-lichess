//
//  LichessClient+Tournaments.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
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
