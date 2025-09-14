import Foundation

extension LichessClient {
  public struct Crosstable: Codable, Sendable, Hashable {
    /// Mapping of username → score (Double).
    public let scores: [String: Double]
    public let nbGames: Int
  }

  /// Get crosstable between two users. Optionally include current match data via `matchup: true`.
  public func getCrosstable(user1: String, user2: String, matchup: Bool? = nil) async throws -> Crosstable {
    let resp = try await underlyingClient.apiCrosstable(
      path: .init(user1: user1, user2: user2),
      query: .init(matchup: matchup)
    )
    switch resp {
    case .ok(let ok):
      let json = try ok.body.json
      return Crosstable(scores: json.users.additionalProperties, nbGames: json.nbGames)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}
