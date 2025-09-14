import Foundation

extension LichessClient {
  public struct FIDEPlayer: Codable, Sendable, Hashable {
    public let id: Int
    public let name: String
    public let title: String?
    public let federation: String?
    public let year: Int?
    public let inactive: Bool?
    public let standard: Int?
    public let rapid: Int?
    public let blitz: Int?
  }

  private func mapFIDE(_ p: Components.Schemas.FIDEPlayer) -> FIDEPlayer {
    FIDEPlayer(
      id: p.id,
      name: p.name,
      title: p.title?.rawValue,
      federation: p.federation,
      year: p.year.map { Int($0) },
      inactive: p.inactive.map { $0 != 0 },
      standard: p.standard,
      rapid: p.rapid,
      blitz: p.blitz
    )
  }

  /// Get a FIDE player by FIDE ID.
  public func getFIDEPlayer(id: Int) async throws -> FIDEPlayer {
    let resp = try await underlyingClient.fidePlayerGet(path: .init(playerId: Double(id)))
    switch resp {
    case .ok(let ok):
      return mapFIDE(try ok.body.json)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Search FIDE players by name query.
  public func searchFIDEPlayers(query: String) async throws -> [FIDEPlayer] {
    let resp = try await underlyingClient.fidePlayerSearch(query: .init(q: query))
    switch resp {
    case .ok(let ok):
      return try ok.body.json.map(mapFIDE)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}
