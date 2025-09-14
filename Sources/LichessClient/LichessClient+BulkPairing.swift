//
//  LichessClient+BulkPairing.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: Models

  public struct BulkPairingGame: Sendable, Hashable {
    public let id: String?
    public let white: String?
    public let black: String?
  }

  public struct BulkPairingInfo: Sendable, Hashable {
    public let id: String
    public let games: [BulkPairingGame]
    public let variant: String
    public let clockLimit: Int
    public let clockIncrement: Int
    public let pairAt: Date
    public let pairedAt: Date?
    public let rated: Bool
    public let startClocksAt: Date
    public let scheduledAt: Date
  }

  public struct BulkPairingCreateOptions: Sendable, Hashable {
    public let variant: String?
    public let fen: String?
    public let pairAt: Date?
    public let startClocksAt: Date?
    public let rated: Bool?
    public let message: String?
    public let daysPerTurn: Int?
    public init(
      variant: String? = nil,
      fen: String? = nil,
      pairAt: Date? = nil,
      startClocksAt: Date? = nil,
      rated: Bool? = nil,
      message: String? = nil,
      daysPerTurn: Int? = nil
    ) {
      self.variant = variant
      self.fen = fen
      self.pairAt = pairAt
      self.startClocksAt = startClocksAt
      self.rated = rated
      self.message = message
      self.daysPerTurn = daysPerTurn
    }
  }

  // MARK: Mapping

  private func mapBulkPairing(_ b: Components.Schemas.BulkPairing) -> BulkPairingInfo {
    let games: [BulkPairingGame] = b.games.map { .init(id: $0.id, white: $0.white, black: $0.black) }
    return BulkPairingInfo(
      id: b.id,
      games: games,
      variant: b.variant.rawValue,
      clockLimit: b.clock.limit,
      clockIncrement: b.clock.increment,
      pairAt: Date(timeIntervalSince1970: TimeInterval(b.pairAt) / 1000.0),
      pairedAt: b.pairedAt.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000.0) },
      rated: b.rated,
      startClocksAt: Date(timeIntervalSince1970: TimeInterval(b.startClocksAt) / 1000.0),
      scheduledAt: Date(timeIntervalSince1970: TimeInterval(b.scheduledAt) / 1000.0)
    )
  }

  // MARK: List / Get

  /// View bulk pairings created by the authenticated user.
  public func listBulkPairings() async throws -> [BulkPairingInfo] {
    let resp = try await underlyingClient.bulkPairingList()
    switch resp {
    case .ok(let ok):
      return try ok.body.json.map(mapBulkPairing)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Show a bulk pairing by ID.
  public func getBulkPairing(id: String) async throws -> BulkPairingInfo {
    let resp = try await underlyingClient.bulkPairingGet(path: .init(id: id))
    switch resp {
    case .ok(let ok):
      return mapBulkPairing(try ok.body.json)
    case .notFound:
      throw LichessClientError.notFound
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: Create / Start / Delete

  /// Create a bulk pairing from player OAuth tokens. For real-time games, provide `clockLimit` and `clockIncrement`. For correspondence, provide `daysPerTurn`.
  public func createBulkPairing(
    pairs: [(whiteToken: String, blackToken: String)],
    clockLimit: Int? = nil,
    clockIncrement: Int? = nil,
    options: BulkPairingCreateOptions = .init()
  ) async throws -> BulkPairingInfo {
    let players = pairs.map { "\($0.whiteToken):\($0.blackToken)" }.joined(separator: ",")
    var body = Operations.bulkPairingCreate.Input.Body.urlEncodedForm(.init(
      players: players,
      clock_period_limit: clockLimit.map(Double.init),
      clock_period_increment: clockIncrement
    ))

    // Mutate optional fields by reconstructing payload (swift-openapi-runtime requires value-type update)
    if case var .urlEncodedForm(payload) = body {
      if let d = options.daysPerTurn {
        let allowed = [1,2,3,5,7,10,14]
        if let v = allowed.first(where: { $0 == d }) {
          payload.days = .init(rawValue: v)
        }
      }
      if let ts = options.pairAt { payload.pairAt = Int64(ts.timeIntervalSince1970 * 1000.0) }
      if let ts = options.startClocksAt { payload.startClocksAt = Int64(ts.timeIntervalSince1970 * 1000.0) }
      if let r = options.rated { payload.rated = r }
      if let v = options.variant, let key = Components.Schemas.VariantKey(rawValue: v) { payload.variant = key }
      if let fen = options.fen { payload.fen = fen }
      if let msg = options.message { payload.message = msg }
      body = .urlEncodedForm(payload)
    }

    let resp = try await underlyingClient.bulkPairingCreate(body: body)
    switch resp {
    case .ok(let ok):
      return mapBulkPairing(try ok.body.json)
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBulkPairing", code: 400, userInfo: [NSLocalizedDescriptionKey: msg]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Immediately start clocks of all games in a bulk pairing.
  public func startBulkPairingClocks(id: String) async throws {
    let resp = try await underlyingClient.bulkPairingStartClocks(path: .init(id: id))
    switch resp {
    case .ok:
      return
    case .notFound:
      throw LichessClientError.notFound
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Cancel and delete a scheduled bulk pairing.
  public func deleteBulkPairing(id: String) async throws {
    let resp = try await underlyingClient.bulkPairingDelete(path: .init(id: id))
    switch resp {
    case .ok:
      return
    case .notFound:
      throw LichessClientError.notFound
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: Export

  /// Export games of a bulk pairing. Returns PGN or NDJSON depending on `format`.
  public func exportBulkPairingGames(
    id: String,
    format: ExportFormat = .pgn,
    moves: Bool? = nil,
    pgnInJson: Bool? = nil,
    tags: Bool? = nil,
    clocks: Bool? = nil,
    evals: Bool? = nil,
    accuracy: Bool? = nil,
    opening: Bool? = nil,
    division: Bool? = nil,
    literate: Bool? = nil
  ) async throws -> HTTPBody {
    let resp = try await underlyingClient.bulkPairingIdGamesGet(
      path: .init(id: id),
      query: .init(
        moves: moves,
        pgnInJson: pgnInJson,
        tags: tags,
        clocks: clocks,
        evals: evals,
        accuracy: accuracy,
        opening: opening,
        division: division,
        literate: literate
      )
    )
    switch resp {
    case .ok(let ok):
      switch ok.body {
      case .application_x_hyphen_chess_hyphen_pgn(let body):
        return body
      case .application_x_hyphen_ndjson(let body):
        return body
      }
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}
