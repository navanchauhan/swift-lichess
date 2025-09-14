//
//  LichessClient+OpeningExplorer.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: Public types
  public struct OpeningExplorerMove: Codable {
    public let uci: String
    public let san: String
    public let averageRating: Double
    public let white: Double
    public let draws: Double
    public let black: Double
  }

  public struct OpeningExplorerGamePlayer: Codable {
    public let name: String
    public let rating: Int
  }

  public struct OpeningExplorerMastersGame: Codable {
    public let id: String
    public let winner: String?
    public let white: OpeningExplorerGamePlayer
    public let black: OpeningExplorerGamePlayer
    public let year: Double
    public let month: String?
  }

  public struct OpeningExplorerMastersTopGame: Codable {
    public let uci: String
    public let game: OpeningExplorerMastersGame
  }

  public struct OpeningExplorerMastersResult: Codable {
    public let white: Double
    public let draws: Double
    public let black: Double
    public let moves: [OpeningExplorerMove]
    public let topGames: [OpeningExplorerMastersTopGame]?
  }

  public struct OpeningExplorerLichessGame: Codable {
    public let id: String
    public let winner: String?
    public let speed: String?
    public let white: OpeningExplorerGamePlayer
    public let black: OpeningExplorerGamePlayer
    public let year: Double
    public let month: String?
  }

  public struct OpeningExplorerLichessGameRef: Codable {
    public let uci: String
    public let game: OpeningExplorerLichessGame
  }

  public struct OpeningExplorerHistory: Codable {
    public let month: String
    public let white: Double
    public let draws: Double
    public let black: Double
  }

  public struct OpeningExplorerLichessResult: Codable {
    public let white: Double
    public let draws: Double
    public let black: Double
    public let moves: [OpeningExplorerMove]
    public let topGames: [OpeningExplorerLichessGameRef]
    public let recentGames: [OpeningExplorerLichessGameRef]?
    public let history: [OpeningExplorerHistory]?
  }

  // MARK: Masters database
  public func getOpeningExplorerMasters(
    fen: String? = nil,
    play: [String]? = nil,
    sinceYear: Double? = nil,
    untilYear: Double? = nil,
    moves: Double? = nil,
    topGames: Double? = nil
  ) async throws -> OpeningExplorerMastersResult {
    let playQuery = play?.joined(separator: ",")
    let response = try await underlyingClient.openingExplorerMaster(
      query: .init(
        fen: fen,
        play: playQuery,
        since: sinceYear,
        until: untilYear,
        moves: moves,
        topGames: topGames
      )
    )
    switch response {
    case .ok(let ok):
      let json = try ok.body.json
      let moves = json.moves.map { m in
        OpeningExplorerMove(
          uci: m.uci, san: m.san, averageRating: m.averageRating, white: m.white, draws: m.draws,
          black: m.black)
      }
      var topGames: [OpeningExplorerMastersTopGame] = []
      for tg in json.topGames {
        let game = tg.value2
        let playerWhite = OpeningExplorerGamePlayer(name: game.white.name, rating: game.white.rating)
        let playerBlack = OpeningExplorerGamePlayer(name: game.black.name, rating: game.black.rating)
        let winnerStr: String? = {
          guard let w = game.winner else { return nil }
          return w.rawValue.isEmpty ? nil : w.rawValue
        }()
        let mapped = OpeningExplorerMastersTopGame(
          uci: tg.value1.uci,
          game: OpeningExplorerMastersGame(
            id: game.id, winner: winnerStr, white: playerWhite, black: playerBlack, year: game.year,
            month: game.month))
        topGames.append(mapped)
      }
      return OpeningExplorerMastersResult(
        white: json.white, draws: json.draws, black: json.black, moves: moves,
        topGames: topGames)
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  // MARK: Lichess games
  public func getOpeningExplorerLichess(
    variant: String? = nil,
    fen: String? = nil,
    play: [String]? = nil,
    speeds: [String]? = nil,
    ratings: [Double]? = nil,
    since: String? = nil,
    until: String? = nil,
    moves: Double? = nil,
    topGames: Double? = nil,
    recentGames: Double? = nil,
    history: Bool? = nil
  ) async throws -> OpeningExplorerLichessResult {
    let playQuery = play?.joined(separator: ",")
    let variantKey = variant.flatMap { Components.Schemas.VariantKey(rawValue: $0) }
    let speedKeys = speeds?.compactMap { Components.Schemas.Speed(rawValue: $0) }
    let response = try await underlyingClient.openingExplorerLichess(
      query: .init(
        variant: variantKey,
        fen: fen,
        play: playQuery,
        speeds: speedKeys,
        ratings: ratings,
        since: since,
        until: until,
        moves: moves,
        topGames: topGames,
        recentGames: recentGames,
        history: history
      )
    )
    switch response {
    case .ok(let ok):
      let json = try ok.body.json
      let moves = json.moves.map { m in
        OpeningExplorerMove(
          uci: m.uci, san: m.san, averageRating: m.averageRating, white: m.white, draws: m.draws,
          black: m.black)
      }
      func mapGame(_ g: Components.Schemas.OpeningExplorerLichessGame) -> OpeningExplorerLichessGame {
        let pw = OpeningExplorerGamePlayer(name: g.white.name, rating: g.white.rating)
        let pb = OpeningExplorerGamePlayer(name: g.black.name, rating: g.black.rating)
        let winnerStr: String? = {
          guard let w = g.winner else { return nil }
          return w.rawValue.isEmpty ? nil : w.rawValue
        }()
        let speedStr = g.speed?.rawValue
        return OpeningExplorerLichessGame(
          id: g.id, winner: winnerStr, speed: speedStr, white: pw, black: pb, year: g.year,
          month: g.month)
      }
      let topGames = json.topGames.map { ref in
        OpeningExplorerLichessGameRef(uci: ref.value1.uci, game: mapGame(ref.value2))
      }
      let recent = json.recentGames?.map { ref in
        OpeningExplorerLichessGameRef(uci: ref.value1.uci, game: mapGame(ref.value2))
      }
      let hist = json.history?.map { h in
        OpeningExplorerHistory(month: h.month, white: h.white, draws: h.draws, black: h.black)
      }
      return OpeningExplorerLichessResult(
        white: json.white, draws: json.draws, black: json.black, moves: moves, topGames: topGames,
        recentGames: recent, history: hist)
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  // MARK: Player games stream (NDJSON)
  public func streamOpeningExplorerPlayer(
    player: String,
    color: String,
    variant: String? = nil,
    fen: String? = nil,
    play: [String]? = nil,
    speeds: [String]? = nil,
    modes: [String]? = nil,
    since: String? = nil,
    until: String? = nil,
    moves: Double? = nil,
    recentGames: Double? = nil
  ) async throws -> HTTPBody {
    let playQuery = play?.joined(separator: ",")
    let mappedModes: Operations.openingExplorerPlayer.Input.Query.modesPayload? = modes?.compactMap {
      switch $0.lowercased() {
      case "rated": return .rated
      case "casual": return .casual
      default: return nil
      }
    }
    let colorPayload: Operations.openingExplorerPlayer.Input.Query.colorPayload =
      color.lowercased() == "black" ? .black : .white
    let variantKey = variant.flatMap { Components.Schemas.VariantKey(rawValue: $0) }
    let speedKeys = speeds?.compactMap { Components.Schemas.Speed(rawValue: $0) }
    let response = try await underlyingClient.openingExplorerPlayer(
      query: .init(
        player: player,
        color: colorPayload,
        variant: variantKey,
        fen: fen,
        play: playQuery,
        speeds: speedKeys,
        modes: mappedModes,
        since: since,
        until: until,
        moves: moves,
        recentGames: recentGames
      )
    )
    switch response {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }
}
