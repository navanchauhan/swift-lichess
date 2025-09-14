import Foundation

extension LichessClient {
  public struct LeaderboardEntry: Codable, Sendable, Hashable {
    public let id: String
    public let username: String
    public let title: String?
    public let rating: Int
    public let progress: Int
    public let patron: Bool?
    public let online: Bool?
  }

  /// Get the top 10 players for each speed and variant.
  /// Returns a dictionary keyed by perf type (e.g. "bullet", "blitz").
  public func getAllTop10() async throws -> [String: [LeaderboardEntry]] {
    let resp = try await underlyingClient.player()
    switch resp {
    case .ok(let ok):
      let top = try ok.body.json
      func mapList(_ users: [Components.Schemas.TopUser], perf: String) -> [LeaderboardEntry] {
        users.map { u in
          let perfs = u.perfs?.additionalProperties ?? [:]
          let perfStats = perfs[perf]
          return LeaderboardEntry(
            id: u.id,
            username: u.username,
            title: u.title?.rawValue,
            rating: perfStats?.rating ?? 0,
            progress: perfStats?.progress ?? 0,
            patron: u.patron,
            online: u.online
          )
        }
      }
      var dict: [String: [LeaderboardEntry]] = [:]
      dict["bullet"] = mapList(top.bullet, perf: "bullet")
      dict["blitz"] = mapList(top.blitz, perf: "blitz")
      dict["rapid"] = mapList(top.rapid, perf: "rapid")
      dict["classical"] = mapList(top.classical, perf: "classical")
      dict["ultraBullet"] = mapList(top.ultraBullet, perf: "ultraBullet")
      dict["crazyhouse"] = mapList(top.crazyhouse, perf: "crazyhouse")
      dict["chess960"] = mapList(top.chess960, perf: "chess960")
      dict["kingOfTheHill"] = mapList(top.kingOfTheHill, perf: "kingOfTheHill")
      dict["threeCheck"] = mapList(top.threeCheck, perf: "threeCheck")
      dict["antichess"] = mapList(top.antichess, perf: "antichess")
      dict["atomic"] = mapList(top.atomic, perf: "atomic")
      dict["horde"] = mapList(top.horde, perf: "horde")
      dict["racingKings"] = mapList(top.racingKings, perf: "racingKings")
      return dict
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Get the leaderboard for a single speed or variant.
  /// - Parameters:
  ///   - perfType: One of the Lichess perf keys (e.g. "bullet", "blitz").
  ///   - nb: Number of users (1...200).
  public func getLeaderboard(perfType: String, nb: Int = 100) async throws -> [LeaderboardEntry] {
    let key = Operations.playerTopNbPerfType.Input.Path.perfTypePayload(rawValue: perfType) ?? .blitz
    let resp = try await underlyingClient.playerTopNbPerfType(path: .init(nb: max(1, min(200, nb)), perfType: key))
    switch resp {
    case .ok(let ok):
      let lb = try ok.body.application_vnd_period_lichess_period_v3_plus_json
      let perf = perfType
      return lb.users.map { u in
        let perfs = u.perfs?.additionalProperties ?? [:]
        let p = perfs[perf]
        return LeaderboardEntry(
          id: u.id,
          username: u.username,
          title: u.title?.rawValue,
          rating: p?.rating ?? 0,
          progress: p?.progress ?? 0,
          patron: u.patron,
          online: u.online
        )
      }
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}

