import Foundation

extension LichessClient {
  public struct CloudEvalPV: Codable, Sendable, Hashable {
    public let cp: Int?
    public let mate: Int?
    public let moves: [String]
  }

  public struct CloudEvalResult: Codable, Sendable, Hashable {
    public let depth: Int
    public let knodes: Int
    public let fen: String
    public let pvs: [CloudEvalPV]
  }

  /// Get the cached cloud evaluation of a FEN, if available.
  /// - Parameters:
  ///   - fen: Position FEN.
  ///   - multiPv: Number of variations to fetch (default 1).
  ///   - variant: Optional variant key (e.g. "standard", "chess960").
  public func getCloudEval(fen: String, multiPv: Int? = nil, variant: String? = nil) async throws -> CloudEvalResult? {
    let variantKey = variant.flatMap { Components.Schemas.VariantKey(rawValue: $0) }
    let resp = try await underlyingClient.apiCloudEval(
      query: .init(fen: fen, multiPv: multiPv.map(Double.init), variant: variantKey)
    )
    switch resp {
    case .ok(let ok):
      let src = try ok.body.json
      let pvs: [CloudEvalPV] = src.pvs.map { pv in
        switch pv {
        case .case1(let cpv):
          return CloudEvalPV(cp: cpv.cp, mate: nil, moves: cpv.moves.split(separator: " ").map(String.init))
        case .case2(let mpv):
          return CloudEvalPV(cp: nil, mate: mpv.mate, moves: mpv.moves.split(separator: " ").map(String.init))
        }
      }
      return CloudEvalResult(depth: src.depth, knodes: src.knodes, fen: src.fen, pvs: pvs)
    case .notFound:
      return nil
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}

