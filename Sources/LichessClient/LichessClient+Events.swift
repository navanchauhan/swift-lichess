import Foundation
import OpenAPIRuntime

extension LichessClient {
  public enum IncomingEvent: Codable, Sendable, Hashable {
    case gameStart(Game)
    case gameFinish(Game)
    case challenge(Challenge)
    case challengeCanceled(String?)
    case challengeDeclined(String?)
    case unknown(String)

    public struct Game: Codable, Sendable, Hashable { public let id: String }
    public struct Challenge: Codable, Sendable, Hashable { public let id: String; public let status: String? }
  }

  /// Open the incoming events stream as an NDJSON HTTPBody.
  /// Use `Streaming.ndjsonStream` to decode incremental items.
  public func streamIncomingEvents() async throws -> HTTPBody {
    let resp = try await underlyingClient.apiStreamEvent()
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Minimal decoder that maps generic event objects into `IncomingEvent`.
  public static func decodeIncomingEvent(from data: Data) -> IncomingEvent? {
    struct Raw: Decodable { let type: String?; let game: Game?; let challenge: Challenge?; struct Game: Decodable { let id: String? }; struct Challenge: Decodable { let id: String?; let status: String? } }
    guard let raw = try? JSONDecoder().decode(Raw.self, from: data), let t = raw.type else { return nil }
    switch t {
    case "gameStart": return raw.game?.id.map { .gameStart(.init(id: $0)) } ?? .unknown(t)
    case "gameFinish": return raw.game?.id.map { .gameFinish(.init(id: $0)) } ?? .unknown(t)
    case "challenge": return raw.challenge?.id.map { .challenge(.init(id: $0, status: raw.challenge?.status)) } ?? .unknown(t)
    case "challengeCanceled": return .challengeCanceled(raw.challenge?.id)
    case "challengeDeclined": return .challengeDeclined(raw.challenge?.id)
    default: return .unknown(t)
    }
  }
}
