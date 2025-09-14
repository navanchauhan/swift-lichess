import Foundation

extension LichessClient {
  public struct SimulVariant: Codable, Sendable, Hashable { public let key: String?; public let name: String?; public let icon: String? }
  public struct SimulHost: Codable, Sendable, Hashable { public let id: String; public let name: String; public let rating: Int?; public let online: Bool? }
  public struct SimulSummary: Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let fullName: String
    public let host: SimulHost
    public let variants: [SimulVariant]
    public let isCreated: Bool
    public let isRunning: Bool
    public let isFinished: Bool
    public let text: String?
    public let estimatedStartAt: Int?
    public let startedAt: Int?
    public let finishedAt: Int?
    public let nbApplicants: Int
    public let nbPairings: Int
  }

  public struct SimulsResponse: Codable, Sendable, Hashable {
    public let created: [SimulSummary]
    public let started: [SimulSummary]
    public let finished: [SimulSummary]
    public let pending: [SimulSummary]
  }

  /// Get recent and ongoing simuls. If authenticated, includes your pending simuls.
  public func getSimuls() async throws -> SimulsResponse {
    let resp = try await underlyingClient.apiSimul()
    switch resp {
    case .ok(let ok):
      let json = try ok.body.json
      func mapOne(_ s: Components.Schemas.Simul) -> SimulSummary {
        let u = s.host.value1
        let extra = s.host.value2
        let host = SimulHost(id: u.id, name: u.name, rating: extra.rating, online: extra.online)
        let mappedVariants: [SimulVariant] = s.variants.map { v in
          SimulVariant(key: v.key?.rawValue, name: v.name, icon: v.icon)
        }
        return SimulSummary(
          id: s.id, name: s.name, fullName: s.fullName, host: host, variants: mappedVariants,
          isCreated: s.isCreated, isRunning: s.isRunning, isFinished: s.isFinished, text: s.text,
          estimatedStartAt: s.estimatedStartAt, startedAt: s.startedAt, finishedAt: s.finishedAt,
          nbApplicants: s.nbApplicants, nbPairings: s.nbPairings)
      }
      return SimulsResponse(
        created: (json.created ?? []).map(mapOne),
        started: (json.started ?? []).map(mapOne),
        finished: (json.finished ?? []).map(mapOne),
        pending: (json.pending ?? []).map(mapOne)
      )
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}
