import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: - Models

  public struct SwissClock: Codable, Sendable, Hashable { public let limitSeconds: Double; public let incrementSeconds: Int }

  public struct SwissTournamentPublic: Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let createdBy: String
    public let startsAt: String
    public let variant: String
    public let round: Int
    public let nbRounds: Int
    public let nbPlayers: Int
    public let nbOngoing: Int
    public let rated: Bool
    public let status: String
    public let clock: SwissClock
    public let nextRoundAt: Date?
    public let nextRoundInSeconds: Int?
  }

  // MARK: - Mapping

  private func mapSwiss(_ s: Components.Schemas.SwissTournament) -> SwissTournamentPublic {
    SwissTournamentPublic(
      id: s.id,
      name: s.name,
      createdBy: s.createdBy,
      startsAt: s.startsAt,
      variant: s.variant,
      round: Int(s.round),
      nbRounds: Int(s.nbRounds),
      nbPlayers: Int(s.nbPlayers),
      nbOngoing: Int(s.nbOngoing),
      rated: s.rated,
      status: s.status.rawValue,
      clock: SwissClock(limitSeconds: s.clock.limit, incrementSeconds: Int(s.clock.increment)),
      nextRoundAt: s.nextRound?.at,
      nextRoundInSeconds: s.nextRound?._in
    )
  }

  // MARK: - Read

  public func getSwissTournament(id: String) async throws -> SwissTournamentPublic {
    let resp = try await underlyingClient.swiss(path: .init(id: id))
    switch resp { case .ok(let ok): return mapSwiss(try ok.body.json); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func getTeamSwissTournaments(teamId: String, max: Int? = nil, status: String? = nil, createdBy: String? = nil, name: String? = nil) async throws -> HTTPBody {
    let st: Operations.apiTeamSwiss.Input.Query.statusPayload?
    if let s = status, let parsed = Components.Schemas.SwissStatus(rawValue: s) {
      st = .init(value1: parsed, value2: try OpenAPIRuntime.OpenAPIValueContainer())
    } else { st = nil }
    let resp = try await underlyingClient.apiTeamSwiss(path: .init(teamId: teamId), query: .init(max: max, status: st, createdBy: createdBy, name: name))
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_ndjson; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - Create/Update

  public struct SwissCreateOptions: Sendable, Hashable {
    public var name: String?
    public var clockLimitSeconds: Double
    public var incrementSeconds: Int
    public var nbRounds: Int
    public var startsAt: Int64?
    public var roundIntervalSeconds: Int?
    public var variantKey: String?
    public var description: String?
    public var rated: Bool?
    public var password: String?
    public init(name: String? = nil, clockLimitSeconds: Double, incrementSeconds: Int, nbRounds: Int, startsAt: Int64? = nil, roundIntervalSeconds: Int? = nil, variantKey: String? = nil, description: String? = nil, rated: Bool? = nil, password: String? = nil) {
      self.name = name; self.clockLimitSeconds = clockLimitSeconds; self.incrementSeconds = incrementSeconds; self.nbRounds = nbRounds; self.startsAt = startsAt; self.roundIntervalSeconds = roundIntervalSeconds; self.variantKey = variantKey; self.description = description; self.rated = rated; self.password = password
    }
  }

  public func createSwissTournament(teamId: String, _ opts: SwissCreateOptions) async throws -> SwissTournamentPublic {
    let body = Operations.apiSwissNew.Input.Body.urlEncodedFormPayload(
      name: opts.name,
      clock_period_limit: opts.clockLimitSeconds,
      clock_period_increment: opts.incrementSeconds,
      nbRounds: opts.nbRounds,
      startsAt: opts.startsAt,
      roundInterval: opts.roundIntervalSeconds.flatMap { Operations.apiSwissNew.Input.Body.urlEncodedFormPayload.roundIntervalPayload(rawValue: $0) },
      variant: opts.variantKey.flatMap { Components.Schemas.VariantKey(rawValue: $0) },
      position: nil,
      description: opts.description,
      rated: opts.rated,
      password: opts.password,
      forbiddenPairings: nil,
      manualPairings: nil,
      chatFor: nil
    )
    let resp = try await underlyingClient.apiSwissNew(path: .init(teamId: teamId), body: .urlEncodedForm(body))
    switch resp { case .ok(let ok): return mapSwiss(try ok.body.json); case .badRequest(let bad): if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "SwissCreate", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }; throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func updateSwissTournament(id: String, _ opts: SwissCreateOptions) async throws -> SwissTournamentPublic {
    let body = Operations.apiSwissUpdate.Input.Body.urlEncodedFormPayload(
      name: opts.name,
      clock_period_limit: opts.clockLimitSeconds,
      clock_period_increment: opts.incrementSeconds,
      nbRounds: opts.nbRounds,
      startsAt: opts.startsAt,
      roundInterval: opts.roundIntervalSeconds.flatMap { Operations.apiSwissUpdate.Input.Body.urlEncodedFormPayload.roundIntervalPayload(rawValue: $0) },
      variant: opts.variantKey.flatMap { Components.Schemas.VariantKey(rawValue: $0) },
      position: nil,
      description: opts.description,
      rated: opts.rated,
      password: opts.password,
      forbiddenPairings: nil,
      manualPairings: nil,
      chatFor: nil
    )
    let resp = try await underlyingClient.apiSwissUpdate(path: .init(id: id), body: .urlEncodedForm(body))
    switch resp { case .ok(let ok): return mapSwiss(try ok.body.json); case .badRequest(let bad): if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "SwissUpdate", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }; throw LichessClientError.httpStatus(statusCode: 400); case .unauthorized: throw LichessClientError.unauthorized; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func scheduleNextSwissRound(id: String, dateMS: Int64?) async throws -> Bool {
    let body = Operations.apiSwissScheduleNextRound.Input.Body.urlEncodedFormPayload(date: dateMS)
    let resp = try await underlyingClient.apiSwissScheduleNextRound(path: .init(id: id), body: .urlEncodedForm(body))
    switch resp { case .noContent: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .unauthorized: throw LichessClientError.unauthorized; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - Join/Withdraw/Terminate

  public func joinSwissTournament(id: String, password: String? = nil) async throws -> Bool {
    let body = password.map { Operations.apiSwissJoin.Input.Body.urlEncodedForm(.init(password: $0)) }
    let resp = try await underlyingClient.apiSwissJoin(path: .init(id: id), body: body)
    switch resp { case .ok: return true; case .badRequest(let bad): if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "SwissJoin", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }; throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func withdrawSwissTournament(id: String) async throws -> Bool {
    let resp = try await underlyingClient.apiSwissWithdraw(path: .init(id: id))
    switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func terminateSwissTournament(id: String) async throws -> Bool {
    let resp = try await underlyingClient.apiSwissTerminate(path: .init(id: id))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - TRF Export

  public func exportSwissTRF(id: String) async throws -> HTTPBody {
    let resp = try await underlyingClient.swissTrf(path: .init(id: id))
    switch resp { case .ok(let ok): return try ok.body.plainText; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }
}
