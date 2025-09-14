//
//  LichessClient+Board.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: Types

  public enum BoardSeekKind: Sendable, Hashable {
    case realtime(timeMinutes: Double, incrementSeconds: Int, color: String? = nil)
    case correspondence(daysPerTurn: Int)
  }

  public struct BoardSeekOptions: Sendable, Hashable {
    public let rated: Bool?
    public let variant: String?
    public let ratingRange: String?
    public init(rated: Bool? = nil, variant: String? = nil, ratingRange: String? = nil) {
      self.rated = rated
      self.variant = variant
      self.ratingRange = ratingRange
    }
  }

  public enum BoardSeekResult: Sendable, Hashable {
    case correspondence(id: String)
    case realtime(HTTPBody)
  }

  public enum ChatRoom: String, Sendable, Hashable { case player, spectator }

  // MARK: Seeks

  /// Create a seek for a board game (realtime or correspondence).
  /// - Returns: `.realtime(HTTPBody)` for realtime seeks (NDJSON stream) or `.correspondence(id)` for correspondence seeks.
  public func createBoardSeek(kind: BoardSeekKind, options: BoardSeekOptions = .init()) async throws -> BoardSeekResult {
    var v1 = Operations.apiBoardSeek.Input.Body.urlEncodedFormPayload.Value1Payload(
      rated: options.rated,
      variant: options.variant.flatMap { Components.Schemas.VariantKey(rawValue: $0) },
      ratingRange: options.ratingRange
    )
    let v2: Operations.apiBoardSeek.Input.Body.urlEncodedFormPayload.Value2Payload
    switch kind {
    case .realtime(let time, let inc, let color):
      let clr = color.flatMap { Operations.apiBoardSeek.Input.Body.urlEncodedFormPayload.Value2Payload.Case1Payload.colorPayload(rawValue: $0) }
      v2 = .case1(.init(time: time, increment: inc, color: clr))
    case .correspondence(let days):
      guard let d = Operations.apiBoardSeek.Input.Body.urlEncodedFormPayload.Value2Payload.Case2Payload.daysPayload(rawValue: days) else {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBoardSeek", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid days per turn: \(days)"]))
      }
      v2 = .case2(.init(days: d))
    }
    let body: Operations.apiBoardSeek.Input.Body = .urlEncodedForm(.init(value1: v1, value2: v2))
    let resp = try await underlyingClient.apiBoardSeek(body: body)
    switch resp {
    case .ok(let ok):
      switch ok.body {
      case .json(let payload):
        return .correspondence(id: payload.id)
      case .application_x_hyphen_ndjson(let nd):
        return .realtime(nd)
      }
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBoardSeek", code: 400, userInfo: [NSLocalizedDescriptionKey: msg]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: Streams

  /// Stream the state of a board game (NDJSON HTTPBody).
  public func streamBoardGame(gameId: String) async throws -> HTTPBody {
    let resp = try await underlyingClient.boardGameStream(path: .init(gameId: gameId))
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .notFound:
      throw LichessClientError.notFound
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Stream chat messages of a board game (NDJSON HTTPBody).
  public func streamBoardChat(gameId: String) async throws -> HTTPBody {
    let resp = try await underlyingClient.boardGameChatGet(path: .init(gameId: gameId))
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: Commands

  /// Play a UCI move in a board game. Optionally offer/agree a draw via `offeringDraw`.
  public func playBoardMove(gameId: String, move: String, offeringDraw: Bool? = nil) async throws -> Bool {
    let resp = try await underlyingClient.boardGameMove(path: .init(gameId: gameId, move: move), query: .init(offeringDraw: offeringDraw))
    switch resp {
    case .ok: return true
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBoardMove", code: 400, userInfo: [NSLocalizedDescriptionKey: msg]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Post a message to the game chat (player or spectator room).
  public func postBoardChat(gameId: String, room: ChatRoom, text: String) async throws -> Bool {
    let roomPayload = Operations.boardGameChatPost.Input.Body.urlEncodedFormPayload.roomPayload(rawValue: room.rawValue) ?? .player
    let body: Operations.boardGameChatPost.Input.Body = .urlEncodedForm(.init(room: roomPayload, text: text))
    let resp = try await underlyingClient.boardGameChatPost(path: .init(gameId: gameId), body: body)
    switch resp {
    case .ok: return true
    case .badRequest(let bad):
      if case let .json(err) = bad.body, let msg = err.error {
        throw LichessClientError.parsingError(error: NSError(domain: "LichessBoardChat", code: 400, userInfo: [NSLocalizedDescriptionKey: msg]))
      }
      throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func abortBoardGame(gameId: String) async throws -> Bool {
    let resp = try await underlyingClient.boardGameAbort(path: .init(gameId: gameId))
    switch resp {
    case .ok: return true
    case .badRequest: throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let status, _): throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func resignBoardGame(gameId: String) async throws -> Bool {
    let resp = try await underlyingClient.boardGameResign(path: .init(gameId: gameId))
    switch resp {
    case .ok: return true
    case .badRequest: throw LichessClientError.httpStatus(statusCode: 400)
    case .undocumented(let status, _): throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func handleBoardDraw(gameId: String, accept: Bool) async throws -> Bool {
    let path = Operations.boardGameDraw.Input.Path(
      gameId: gameId,
      accept: accept ? .init(value2: .yes) : .init(value1: false)
    )
    let resp = try await underlyingClient.boardGameDraw(path: path)
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func handleBoardTakeback(gameId: String, accept: Bool) async throws -> Bool {
    let path = Operations.boardGameTakeback.Input.Path(
      gameId: gameId,
      accept: accept ? .init(value2: .yes) : .init(value1: false)
    )
    let resp = try await underlyingClient.boardGameTakeback(path: path)
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func claimBoardVictory(gameId: String) async throws -> Bool {
    let resp = try await underlyingClient.boardGameClaimVictory(path: .init(gameId: gameId))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func claimBoardDraw(gameId: String) async throws -> Bool {
    let resp = try await underlyingClient.boardGameClaimDraw(path: .init(gameId: gameId))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func berserkBoardGame(gameId: String) async throws -> Bool {
    let resp = try await underlyingClient.boardGameBerserk(path: .init(gameId: gameId))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }
}

