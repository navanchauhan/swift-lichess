//
//  LichessClient+Challenges.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: Models

  public struct ChallengeUserInfo: Sendable, Hashable {
    public let id: String
    public let name: String
    public let rating: Int?
    public let flair: String?
    public let patron: Bool?
    public let provisional: Bool?
    public let online: Bool?
  }

  public struct ChallengeInfo: Sendable, Hashable {
    public let id: String
    public let url: String
    public let status: String
    public let challenger: ChallengeUserInfo
    public let variant: String
    public let rated: Bool
    public let speed: String
    public let color: String
    public let finalColor: String?
    public let initialFEN: String?
  }

  public struct ChallengeLists: Sendable, Hashable {
    public let incoming: [ChallengeInfo]
    public let outgoing: [ChallengeInfo]
  }

  public struct OpenChallenge: Sendable, Hashable {
    public let id: String
    public let url: String
    public let urlWhite: String
    public let urlBlack: String
    public let variant: String
    public let rated: Bool
    public let speed: String
    public let color: String
    public let initialFEN: String?
  }

  public enum ChallengeTime: Sendable, Hashable {
    case realtime(limitSeconds: Double, incrementSeconds: Int)
    case correspondence(daysPerTurn: Int)
  }

  // MARK: Mapping
  private func map(_ u: Components.Schemas.ChallengeUser) -> ChallengeUserInfo {
    .init(
      id: u.id,
      name: u.name,
      rating: u.rating.map { Int($0) },
      flair: u.flair,
      patron: u.patron,
      provisional: u.provisional,
      online: u.online
    )
  }

  private func map(_ c: Components.Schemas.ChallengeJson) -> ChallengeInfo {
    .init(
      id: c.id,
      url: c.url,
      status: c.status.rawValue,
      challenger: map(c.challenger),
      variant: c.variant.key.rawValue,
      rated: c.rated,
      speed: c.speed.rawValue,
      color: c.color.rawValue,
      finalColor: c.finalColor?.rawValue,
      initialFEN: c.initialFen
    )
  }

  private func map(_ o: Components.Schemas.ChallengeOpenJson) -> OpenChallenge {
    .init(
      id: o.id,
      url: o.url,
      urlWhite: o.urlWhite,
      urlBlack: o.urlBlack,
      variant: o.variant.key.rawValue,
      rated: o.rated,
      speed: o.speed.rawValue,
      color: o.color.rawValue,
      initialFEN: o.initialFen
    )
  }

  // MARK: List & Show
  public func listChallenges() async throws -> ChallengeLists {
    let resp = try await underlyingClient.challengeList()
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      let incoming = (payload._in ?? []).map(map)
      let outgoing = (payload.out ?? []).map(map)
      return .init(incoming: incoming, outgoing: outgoing)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func showChallenge(id: String) async throws -> ChallengeInfo {
    let resp = try await underlyingClient.challengeShow(path: .init(challengeId: id))
    switch resp { case .ok(let ok): return map(try ok.body.json); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: Create
  public struct CreateChallengeOptions: Sendable, Hashable {
    public let rated: Bool?
    public let color: String?
    public let variant: String?
    public let fen: String?
    public let rules: String?
    public init(rated: Bool? = nil, color: String? = nil, variant: String? = nil, fen: String? = nil, rules: String? = nil) {
      self.rated = rated; self.color = color; self.variant = variant; self.fen = fen; self.rules = rules
    }
  }

  public func createChallenge(
    username: String,
    time: ChallengeTime,
    options: CreateChallengeOptions = .init()
  ) async throws -> ChallengeInfo {
    // Value1: time control
    let v1: Operations.challengeCreate.Input.Body.urlEncodedFormPayload.Value1Payload
    switch time {
    case .realtime(let limit, let inc):
      v1 = .case1(.init(clock_period_limit: limit, clock_period_increment: inc))
    case .correspondence(let days):
      guard let d = Operations.challengeCreate.Input.Body.urlEncodedFormPayload.Value1Payload.Case2Payload.daysPayload(rawValue: days) else {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessChallenge", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid days per turn: \(days)"]))
      }
      v1 = .case2(.init(days: d))
    }
    // Value2: misc
    let colorPayload = options.color.flatMap { Operations.challengeCreate.Input.Body.urlEncodedFormPayload.Value2Payload.colorPayload(rawValue: $0) }
    let variantKey = options.variant.flatMap { Components.Schemas.VariantKey(rawValue: $0) }
    var v2 = Operations.challengeCreate.Input.Body.urlEncodedFormPayload.Value2Payload(
      rated: options.rated, color: colorPayload, variant: variantKey, fen: options.fen, keepAliveStream: nil, rules: nil
    )
    if let r = options.rules, let parsed = Operations.challengeCreate.Input.Body.urlEncodedFormPayload.Value2Payload.rulesPayload(rawValue: r) { v2.rules = parsed }

    let body: Operations.challengeCreate.Input.Body = .urlEncodedForm(.init(value1: v1, value2: v2))
    let resp = try await underlyingClient.challengeCreate(path: .init(username: username), body: body)
    switch resp {
    case .ok(let ok): return map(try ok.body.json)
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "LichessChallenge", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  public func openChallenge(
    rated: Bool? = nil,
    initialLimitSeconds: Double? = nil,
    incrementSeconds: Int? = nil,
    daysPerTurn: Int? = nil,
    variant: String? = nil,
    fen: String? = nil
  ) async throws -> OpenChallenge {
    var payload = Operations.challengeOpen.Input.Body.urlEncodedFormPayload(
      rated: rated,
      clock_period_limit: initialLimitSeconds,
      clock_period_increment: incrementSeconds,
      days: nil,
      variant: variant.flatMap { Components.Schemas.VariantKey(rawValue: $0) },
      fen: fen,
      name: nil,
      rules: nil,
      users: nil,
      expiresAt: nil
    )
    if let d = daysPerTurn, let dd = Operations.challengeOpen.Input.Body.urlEncodedFormPayload.daysPayload(rawValue: d) { payload.days = dd }
    let resp = try await underlyingClient.challengeOpen(body: .urlEncodedForm(payload))
    switch resp {
    case .ok(let ok): return map(try ok.body.json)
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "LichessOpenChallenge", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  // MARK: Accept/Decline/Cancel
  public func acceptChallenge(id: String, color: String? = nil) async throws -> Bool {
    let cp = color.flatMap { Operations.challengeAccept.Input.Query.colorPayload(rawValue: $0) }
    let resp = try await underlyingClient.challengeAccept(path: .init(challengeId: id), query: .init(color: cp))
    switch resp { case .ok: return true; case .notFound: throw LichessClientError.notFound; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func declineChallenge(id: String) async throws -> Bool {
    let resp = try await underlyingClient.challengeDecline(path: .init(challengeId: id))
    switch resp { case .ok: return true; case .notFound: throw LichessClientError.notFound; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func cancelChallenge(id: String, opponentToken: String? = nil) async throws -> Bool {
    let resp = try await underlyingClient.challengeCancel(path: .init(challengeId: id), query: .init(opponentToken: opponentToken))
    switch resp { case .ok: return true; case .notFound: throw LichessClientError.notFound; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: AI & Start Clocks
  public func createAIChallenge(
    level: Int,
    limitSeconds: Double? = nil,
    incrementSeconds: Int? = nil,
    daysPerMove: Int? = nil,
    color: String? = nil,
    variant: String? = nil,
    fen: String? = nil
  ) async throws -> String {
    var body = Operations.challengeAi.Input.Body.urlEncodedFormPayload(
      level: Double(level),
      clock_period_limit: limitSeconds,
      clock_period_increment: incrementSeconds,
      days: nil,
      color: color.flatMap { Operations.challengeAi.Input.Body.urlEncodedFormPayload.colorPayload(rawValue: $0) },
      variant: variant.flatMap { Components.Schemas.VariantKey(rawValue: $0) },
      fen: fen
    )
    if let d = daysPerMove, let dd = Operations.challengeAi.Input.Body.urlEncodedFormPayload.daysPayload(rawValue: d) { body.days = dd }
    let resp = try await underlyingClient.challengeAi(body: .urlEncodedForm(body))
    switch resp {
    case .created(let created):
      let j = try created.body.json
      return j.id ?? (j.fullId ?? "")
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error { throw LichessClientError.parsingError(error: NSError(domain: "LichessAIChallenge", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])) }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  public func startClocks(gameId: String, token1: String, token2: String? = nil) async throws -> Bool {
    let resp = try await underlyingClient.challengeStartClocks(path: .init(gameId: gameId), query: .init(token1: token1, token2: token2))
    switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }
}
