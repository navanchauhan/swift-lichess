//
//  LichessClient+Bot.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  public enum BotChatRoom: String, Sendable, Hashable { case player, spectator }

  /// Stream online bots as NDJSON HTTPBody.
  public func streamOnlineBots(nb: Int? = nil) async throws -> HTTPBody {
    let resp = try await underlyingClient.apiBotOnline()
    switch resp {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  /// Upgrade the current account to a Bot account.
  public func upgradeToBotAccount() async throws -> Bool {
    let resp = try await underlyingClient.botAccountUpgrade()
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Stream a Bot game state as NDJSON.
  public func streamBotGame(gameId: String) async throws -> HTTPBody {
    let resp = try await underlyingClient.botGameStream(path: .init(gameId: gameId))
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_ndjson; case .notFound: throw LichessClientError.notFound; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Make a move in a Bot game (UCI). Optionally offer/agree draw.
  public func playBotMove(gameId: String, move: String, offeringDraw: Bool? = nil) async throws -> Bool {
    let resp = try await underlyingClient.botGameMove(path: .init(gameId: gameId, move: move), query: .init(offeringDraw: offeringDraw))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Stream chat of a Bot game as NDJSON.
  public func streamBotChat(gameId: String) async throws -> HTTPBody {
    let resp = try await underlyingClient.botGameChatGet(path: .init(gameId: gameId))
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_ndjson; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  /// Post a message to a Bot game chat.
  public func postBotChat(gameId: String, room: BotChatRoom, text: String) async throws -> Bool {
    let roomPayload = Operations.botGameChat.Input.Body.urlEncodedFormPayload.roomPayload(rawValue: room.rawValue) ?? .player
    let resp = try await underlyingClient.botGameChat(path: .init(gameId: gameId), body: .urlEncodedForm(.init(room: roomPayload, text: text)))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func abortBotGame(gameId: String) async throws -> Bool {
    let resp = try await underlyingClient.botGameAbort(path: .init(gameId: gameId))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func resignBotGame(gameId: String) async throws -> Bool {
    let resp = try await underlyingClient.botGameResign(path: .init(gameId: gameId))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func handleBotDraw(gameId: String, accept: Bool) async throws -> Bool {
    let path = Operations.botGameDraw.Input.Path(gameId: gameId, accept: accept ? .init(value2: .yes) : .init(value1: false))
    let resp = try await underlyingClient.botGameDraw(path: path)
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func handleBotTakeback(gameId: String, accept: Bool) async throws -> Bool {
    let path = Operations.botGameTakeback.Input.Path(gameId: gameId, accept: accept ? .init(value2: .yes) : .init(value1: false))
    let resp = try await underlyingClient.botGameTakeback(path: path)
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func claimBotVictory(gameId: String) async throws -> Bool {
    let resp = try await underlyingClient.botGameClaimVictory(path: .init(gameId: gameId))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func claimBotDraw(gameId: String) async throws -> Bool {
    let resp = try await underlyingClient.botGameClaimDraw(path: .init(gameId: gameId))
    switch resp { case .ok: return true; case .badRequest: throw LichessClientError.httpStatus(statusCode: 400); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }
}
