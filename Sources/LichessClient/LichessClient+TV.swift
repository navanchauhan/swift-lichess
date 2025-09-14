import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: - Public types

  public enum TVChannel: String, Codable, CaseIterable, Sendable {
    case bot, blitz, racingKings, ultraBullet, bullet, classical, threeCheck, antichess, computer, horde, rapid, atomic, crazyhouse, chess960, kingOfTheHill, best
  }

  public struct TVUser: Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let flair: String?
    public let title: String?
    public let patron: Bool?
  }

  public struct TVGame: Codable, Sendable, Hashable {
    public let user: TVUser
    public let rating: Int
    public let gameId: String
    public let color: String
  }

  public struct TVChannels: Codable, Sendable, Hashable {
    public let entries: [TVChannel: TVGame]
  }

  public enum TVFeedEvent: Sendable, Hashable {
    case featured(Featured)
    case fen(FEN)

    public struct Player: Codable, Sendable, Hashable {
      public let color: String
      public let user: TVUser
      public let rating: Int
      public let seconds: Int
    }

    public struct Featured: Codable, Sendable, Hashable {
      public let id: String
      public let orientation: String
      public let players: [Player] // always 2
      public let fen: String
    }

    public struct FEN: Codable, Sendable, Hashable {
      public let fen: String
      public let lm: String
      public let wc: Int
      public let bc: Int
    }
  }

  // MARK: - Helpers (mapping generator payloads)

  private func mapLightUser(_ u: Components.Schemas.LightUser) -> TVUser {
    TVUser(id: u.id, name: u.name, flair: u.flair, title: u.title?.rawValue, patron: u.patron)
  }

  private func mapTvGame(_ g: Components.Schemas.TvGame) -> TVGame {
    TVGame(user: mapLightUser(g.user), rating: Int(g.rating), gameId: g.gameId, color: g.color.rawValue)
  }

  // MARK: - Public API

  /// Get the current Lichess TV channels with their featured games.
  public func getTVChannels() async throws -> TVChannels {
    let resp = try await underlyingClient.tvChannels()
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      var dict: [TVChannel: TVGame] = [:]
      dict[.bot] = mapTvGame(payload.bot)
      dict[.blitz] = mapTvGame(payload.blitz)
      dict[.racingKings] = mapTvGame(payload.racingKings)
      dict[.ultraBullet] = mapTvGame(payload.ultraBullet)
      dict[.bullet] = mapTvGame(payload.bullet)
      dict[.classical] = mapTvGame(payload.classical)
      dict[.threeCheck] = mapTvGame(payload.threeCheck)
      dict[.antichess] = mapTvGame(payload.antichess)
      dict[.computer] = mapTvGame(payload.computer)
      dict[.horde] = mapTvGame(payload.horde)
      dict[.rapid] = mapTvGame(payload.rapid)
      dict[.atomic] = mapTvGame(payload.atomic)
      dict[.crazyhouse] = mapTvGame(payload.crazyhouse)
      dict[.chess960] = mapTvGame(payload.chess960)
      dict[.kingOfTheHill] = mapTvGame(payload.kingOfTheHill)
      dict[.best] = mapTvGame(payload.best)
      return TVChannels(entries: dict)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Stream the current TV game for a given channel as NDJSON.
  /// Returns the raw NDJSON body suitable for `Streaming.ndjsonStream`.
  public func streamTVChannelFeed(channel: String) async throws -> HTTPBody {
    let resp = try await underlyingClient.tvChannelFeed(path: .init(channel: channel))
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Decode a `TVFeedEvent` from a single decoded NDJSON line provided by the generator.
  static func decodeTVFeedEvent(_ v: Components.Schemas.TvFeed) -> TVFeedEvent? {
    switch v.t {
    case .featured:
      guard case .case1(let d) = v.d else { return nil }
      let players = d.players.map { p in
        TVFeedEvent.Player(color: p.color.rawValue, user: TVUser(id: p.user.id, name: p.user.name, flair: p.user.flair, title: p.user.title?.rawValue, patron: p.user.patron), rating: p.rating, seconds: p.seconds)
      }
      return .featured(.init(id: d.id, orientation: d.orientation.rawValue, players: players, fen: d.fen))
    case .fen:
      guard case .case2(let d) = v.d else { return nil }
      return .fen(.init(fen: d.fen, lm: d.lm, wc: d.wc, bc: d.bc))
    }
  }

  /// Get best ongoing games for a specific TV channel. Returns PGN or NDJSON based on `format`.
  public func getTVChannelGames(
    channel: String,
    format: ExportFormat = .pgn,
    nb: Int? = nil,
    moves: Bool? = nil,
    pgnInJson: Bool? = nil,
    tags: Bool? = nil,
    clocks: Bool? = nil,
    opening: Bool? = nil
  ) async throws -> HTTPBody {
    // Map export format to Accept header
    let accept: [OpenAPIRuntime.AcceptHeaderContentType<Operations.tvChannelGames.AcceptableContentType>] = {
      switch format {
      case .pgn: return [.init(contentType: .application_x_hyphen_chess_hyphen_pgn)]
      case .ndjson: return [.init(contentType: .application_x_hyphen_ndjson)]
      }
    }()
    let resp = try await underlyingClient.tvChannelGames(
      path: .init(channel: channel),
      query: .init(nb: nb.map(Double.init), moves: moves, pgnInJson: pgnInJson, tags: tags, clocks: clocks, opening: opening),
      headers: .init(accept: accept)
    )
    switch resp {
    case .ok(let ok):
      switch ok.body {
      case .application_x_hyphen_chess_hyphen_pgn(let body): return body
      case .application_x_hyphen_ndjson(let body): return body
      }
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}
