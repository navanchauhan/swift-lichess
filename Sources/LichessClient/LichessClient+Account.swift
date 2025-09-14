import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: - Public types

  public struct Preferences: Codable, Sendable {
    public let language: String?
    public let dark: Bool?
    public let is3d: Bool?
    public let theme: String?
    public let pieceSet: String?
    public let theme3d: String?
    public let pieceSet3d: String?
    public let soundSet: String?
    public let blindfold: Int?
    public let autoQueen: Int?
    public let premove: Bool?
    public let animation: Int?
    public let coords: Int?
  }

  public struct OngoingGameSummary: Codable, Sendable, Hashable {
    public let gameId: String
    public let color: String
    public let lastMove: String
    public let variant: String
    public let speed: String
    public let perf: String
    public let rated: Bool
    public let isMyTurn: Bool
    public let secondsLeft: Double
    public let opponentName: String?
    public let opponentRating: Int?
  }

  // MARK: - Mapping helpers

  private func mapPreferences(_ prefs: Components.Schemas.UserPreferences?) -> LichessClient.Preferences {
    let dark: Bool? = prefs?.dark
    let is3d: Bool? = prefs?.is3d
    let theme: String? = prefs?.theme?.rawValue
    let pieceSet: String? = prefs?.pieceSet?.rawValue
    let theme3d: String? = prefs?.theme3d?.rawValue
    let pieceSet3d: String? = prefs?.pieceSet3d?.rawValue
    let soundSet: String? = prefs?.soundSet?.rawValue
    let blindfold: Int? = prefs?.blindfold
    let autoQueen: Int? = prefs?.autoQueen
    let premove: Bool? = prefs?.premove
    let animation: Int? = prefs?.animation
    let coords: Int? = prefs?.coords
    return LichessClient.Preferences(
      language: nil,
      dark: dark,
      is3d: is3d,
      theme: theme,
      pieceSet: pieceSet,
      theme3d: theme3d,
      pieceSet3d: pieceSet3d,
      soundSet: soundSet,
      blindfold: blindfold,
      autoQueen: autoQueen,
      premove: premove,
      animation: animation,
      coords: coords
    )
  }

  private func mapOngoing(_ g: Operations.apiAccountPlaying.Output.Ok.Body.jsonPayload.nowPlayingPayloadPayload) -> OngoingGameSummary {
    return OngoingGameSummary(
      gameId: g.gameId,
      color: g.color.rawValue,
      lastMove: g.lastMove,
      variant: g.variant.key.rawValue,
      speed: g.speed.rawValue,
      perf: g.perf.rawValue,
      rated: g.rated,
      isMyTurn: g.isMyTurn,
      secondsLeft: g.secondsLeft,
      opponentName: g.opponent.username,
      opponentRating: g.opponent.rating.map { Int($0) }
    )
  }

  // MARK: - Public API

  /// Get the current user preferences and language.
  public func getMyPreferences() async throws -> LichessClient.Preferences {
    let resp = try await underlyingClient.account()
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      var mapped: LichessClient.Preferences = mapPreferences(payload.prefs)
      // inject language that lives alongside prefs
      mapped = LichessClient.Preferences(
        language: payload.language,
        dark: mapped.dark,
        is3d: mapped.is3d,
        theme: mapped.theme,
        pieceSet: mapped.pieceSet,
        theme3d: mapped.theme3d,
        pieceSet3d: mapped.pieceSet3d,
        soundSet: mapped.soundSet,
        blindfold: mapped.blindfold,
        autoQueen: mapped.autoQueen,
        premove: mapped.premove,
        animation: mapped.animation,
        coords: mapped.coords
      )
      return mapped
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Read kid mode status of the logged-in user.
  public func getKidMode() async throws -> Bool {
    let resp = try await underlyingClient.accountKid()
    switch resp {
    case .ok(let ok):
      return try ok.body.json.kid ?? false
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Set kid mode status of the logged-in user.
  public func setKidMode(_ enabled: Bool) async throws -> Bool {
    let resp = try await underlyingClient.accountKidPost(query: .init(v: enabled))
    switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Get ongoing games of the current user (most urgent first).
  public func getMyOngoingGames(nb: Int? = nil) async throws -> [OngoingGameSummary] {
    let resp = try await underlyingClient.apiAccountPlaying(query: .init(nb: nb))
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      return payload.nowPlaying.map(mapOngoing)
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }
}
