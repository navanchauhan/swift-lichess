//
//  LichessClient+ExternalEngine.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: Models

  public struct ExternalEngineInfo: Sendable, Hashable {
    public let id: String
    public let name: String
    public let clientSecret: String
    public let userId: String
    public let maxThreads: Int
    public let maxHash: Int
    public let variants: [String]
    public let providerData: String?
  }

  public struct ExternalEngineRegistrationOptions: Sendable, Hashable {
    public let variants: [String]?
    public let providerData: String?
    public init(variants: [String]? = nil, providerData: String? = nil) {
      self.variants = variants
      self.providerData = providerData
    }
  }

  public struct ExternalEngineWorkCommon: Sendable, Hashable {
    public let sessionId: String
    public let threads: Int
    public let hash: Int
    public let multiPv: Int
    public let variant: String
    public let initialFEN: String
    public let moves: [String]
    public init(sessionId: String, threads: Int, hash: Int, multiPv: Int, variant: String, initialFEN: String, moves: [String]) {
      self.sessionId = sessionId
      self.threads = threads
      self.hash = hash
      self.multiPv = multiPv
      self.variant = variant
      self.initialFEN = initialFEN
      self.moves = moves
    }
  }

  public enum ExternalEngineWork: Sendable, Hashable {
    case movetime(ms: Int, common: ExternalEngineWorkCommon)
    case depth(ply: Int, common: ExternalEngineWorkCommon)
    case nodes(count: Int, common: ExternalEngineWorkCommon)
  }

  public struct ExternalEngineAcquire: Sendable, Hashable {
    public let id: String
    public let work: ExternalEngineWork
    public let engine: ExternalEngineInfo
  }

  // MARK: Mapping helpers

  private func mapExternal(_ e: Components.Schemas.ExternalEngine) -> ExternalEngineInfo {
    ExternalEngineInfo(
      id: e.id,
      name: e.name,
      clientSecret: e.clientSecret,
      userId: e.userId,
      maxThreads: e.maxThreads,
      maxHash: e.maxHash,
      variants: e.variants.map { $0.rawValue },
      providerData: e.providerData
    )
  }

  private func mapWorkCommon(_ c: Components.Schemas.ExternalEngineWorkCommon) -> ExternalEngineWorkCommon {
    .init(
      sessionId: c.sessionId,
      threads: c.threads,
      hash: c.hash,
      multiPv: c.multiPv,
      variant: c.variant.rawValue,
      initialFEN: c.initialFen,
      moves: c.moves
    )
  }

  private func mapWork(_ w: Components.Schemas.ExternalEngineWork) -> ExternalEngineWork {
    switch w {
    case .case1(let p):
      return .movetime(ms: p.value1.movetime, common: mapWorkCommon(p.value2))
    case .case2(let p):
      return .depth(ply: p.value1.depth, common: mapWorkCommon(p.value2))
    case .case3(let p):
      return .nodes(count: p.value1.nodes, common: mapWorkCommon(p.value2))
    }
  }

  private func toUciVariant(_ key: String) -> Components.Schemas.UciVariant? {
    Components.Schemas.UciVariant(rawValue: key)
  }

  private func toWork(_ w: ExternalEngineWork) -> Components.Schemas.ExternalEngineWork {
    switch w {
    case .movetime(let ms, let common):
      return .case1(.init(
        value1: .init(movetime: ms),
        value2: .init(
          sessionId: common.sessionId,
          threads: common.threads,
          hash: common.hash,
          multiPv: common.multiPv,
          variant: toUciVariant(common.variant) ?? .chess,
          initialFen: common.initialFEN,
          moves: common.moves
        )
      ))
    case .depth(let ply, let common):
      return .case2(.init(
        value1: .init(depth: ply),
        value2: .init(
          sessionId: common.sessionId,
          threads: common.threads,
          hash: common.hash,
          multiPv: common.multiPv,
          variant: toUciVariant(common.variant) ?? .chess,
          initialFen: common.initialFEN,
          moves: common.moves
        )
      ))
    case .nodes(let count, let common):
      return .case3(.init(
        value1: .init(nodes: count),
        value2: .init(
          sessionId: common.sessionId,
          threads: common.threads,
          hash: common.hash,
          multiPv: common.multiPv,
          variant: toUciVariant(common.variant) ?? .chess,
          initialFen: common.initialFEN,
          moves: common.moves
        )
      ))
    }
  }

  // MARK: CRUD

  /// List external engines registered for the authenticated user.
  public func listExternalEngines() async throws -> [ExternalEngineInfo] {
    let resp = try await underlyingClient.apiExternalEngineList()
    switch resp {
    case .ok(let ok):
      return try ok.body.json.map(mapExternal)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Register a new external engine.
  public func registerExternalEngine(
    name: String,
    maxThreads: Int,
    maxHash: Int,
    providerSecret: String,
    options: ExternalEngineRegistrationOptions = .init()
  ) async throws -> ExternalEngineInfo {
    let variants = options.variants?.compactMap { Components.Schemas.UciVariant(rawValue: $0) }
    let body = Operations.apiExternalEngineCreate.Input.Body.json(.init(
      name: name,
      maxThreads: maxThreads,
      maxHash: maxHash,
      variants: variants,
      providerSecret: providerSecret,
      providerData: options.providerData
    ))
    let resp = try await underlyingClient.apiExternalEngineCreate(body: body)
    switch resp {
    case .ok(let ok):
      return mapExternal(try ok.body.json)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Get one external engine.
  public func getExternalEngine(id: String) async throws -> ExternalEngineInfo {
    let resp = try await underlyingClient.apiExternalEngineGet(path: .init(id: id))
    switch resp {
    case .ok(let ok):
      return mapExternal(try ok.body.json)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Update an external engine.
  public func updateExternalEngine(
    id: String,
    name: String,
    maxThreads: Int,
    maxHash: Int,
    providerSecret: String,
    variants: [String]? = nil,
    providerData: String? = nil
  ) async throws -> ExternalEngineInfo {
    let json = Operations.apiExternalEnginePut.Input.Body.json(.init(
      name: name,
      maxThreads: maxThreads,
      maxHash: maxHash,
      variants: variants?.compactMap { Components.Schemas.UciVariant(rawValue: $0) },
      providerSecret: providerSecret,
      providerData: providerData
    ))
    let resp = try await underlyingClient.apiExternalEnginePut(path: .init(id: id), body: json)
    switch resp {
    case .ok(let ok):
      return mapExternal(try ok.body.json)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Delete an external engine.
  public func deleteExternalEngine(id: String) async throws {
    let resp = try await underlyingClient.apiExternalEngineDelete(path: .init(id: id))
    switch resp {
    case .ok:
      return
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: Analyse (consumer)

  /// Request analysis from an external engine as an NDJSON HTTPBody stream.
  public func analyseWithExternalEngine(id: String, clientSecret: String, work: ExternalEngineWork) async throws -> HTTPBody {
    let resp = try await underlyingClient.apiExternalEngineAnalyse(
      path: .init(id: id),
      body: .json(.init(clientSecret: clientSecret, work: toWork(work)))
    )
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: Provider endpoints

  /// Long-poll to acquire one pending analysis request for this provider.
  public func acquireExternalEngineWork(providerSecret: String) async throws -> ExternalEngineAcquire? {
    let resp = try await underlyingClient.apiExternalEngineAcquire(body: .json(.init(providerSecret: providerSecret)))
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      return ExternalEngineAcquire(
        id: payload.id,
        work: mapWork(payload.work),
        engine: mapExternal(payload.engine)
      )
    case .noContent:
      return nil
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Submit UCI lines for a previously acquired work item.
  public func submitExternalEngineWork(id: String, uciStream: HTTPBody) async throws {
    let resp = try await underlyingClient.apiExternalEngineSubmit(path: .init(id: id), body: .plainText(uciStream))
    switch resp {
    case .ok:
      return
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}
