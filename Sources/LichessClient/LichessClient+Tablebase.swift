//
//  LichessClient+Tablebase.swift
//
//
//  Created by Navan Chauhan on 4/23/24.
//

import Foundation

extension LichessClient {
  public struct TablebaseLookup: Codable {
    public let dtz: Int?
    public let precise_dtz: Int?
    public let dtm: Int?
    public let checkmate: Bool?
    public let stalemate: Bool?
    public let variant_win: Bool?
    public let variant_loss: Bool?
    public let insufficient_material: Bool?
    public let category: TablebaseCategory?
    public var moves: [TablebaseMove]?
  }

  public struct TablebaseMove: Codable {
    public let uci: String?
    public let san: String?
    public let dtz: Int?
    public let precise_dtz: Int?
    public let dtm: Int?
    public let zeroing: Bool?
    public let checkmate: Bool?
    public let stalemate: Bool?
    public let variant_win: Bool?
    public let variant_loss: Bool?
    public let insufficient_material: Bool?
    public let category: TablebaseCategory?
  }

  public enum TablebaseCategory: Codable {
    case win
    case unknown
    case maybe_hyphen_win
    case cursed_hyphen_win
    case draw
    case blessed_hyphen_loss
    case maybe_hyphen_loss
    case loss
    case syzygy_hyphen_win
    case syzygy_hyphen_loss
  }

  func convertCategoryTablebaseJson(payload: Components.Schemas.TablebaseJson.categoryPayload?)
    -> TablebaseCategory?
  {
    guard let payload = payload else { return nil }
    switch payload {
    case .win:
      return .win
    case .unknown:
      return .unknown
    case .maybe_hyphen_win:
      return .maybe_hyphen_win
    case .cursed_hyphen_win:
      return .cursed_hyphen_win
    case .draw:
      return .draw
    case .blessed_hyphen_loss:
      return .blessed_hyphen_loss
    case .maybe_hyphen_loss:
      return .maybe_hyphen_loss
    case .loss:
      return .loss
    case .syzygy_hyphen_win:
      return .syzygy_hyphen_win
    case .syzygy_hyphen_loss:
      return .syzygy_hyphen_loss
    }
  }

  func convertCategoryTablebaseJsonMoves(payload: Components.Schemas.Move.categoryPayload?)
    -> TablebaseCategory?
  {
    guard let payload = payload else { return nil }
    switch payload {
    case .win:
      return .win
    case .unknown:
      return .unknown
    case .maybe_hyphen_win:
      return .maybe_hyphen_win
    case .cursed_hyphen_win:
      return .cursed_hyphen_win
    case .draw:
      return .draw
    case .blessed_hyphen_loss:
      return .blessed_hyphen_loss
    case .maybe_hyphen_loss:
      return .maybe_hyphen_loss
    case .loss:
      return .loss
    case .syzygy_hyphen_loss:
      return .syzygy_hyphen_loss
    case .syzygy_hyphen_win:
      return .syzygy_hyphen_win
    }
  }

  public func getStandardTablebase(fen: String) async throws -> TablebaseLookup {
    let response = try await underlyingTablebaseClient.tablebaseStandard(query: .init(fen: fen))
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let tablebaseJson):
        var tablebaseLookup = TablebaseLookup(
          dtz: tablebaseJson.dtz, precise_dtz: tablebaseJson.precise_dtz, dtm: tablebaseJson.dtm,
          checkmate: tablebaseJson.checkmate, stalemate: tablebaseJson.stalemate,
          variant_win: tablebaseJson.variant_win, variant_loss: tablebaseJson.variant_loss,
          insufficient_material: tablebaseJson.insufficient_material,
          category: convertCategoryTablebaseJson(payload: tablebaseJson.category), moves: [])

        guard let moves = tablebaseJson.moves else {
          return tablebaseLookup
        }
        var tablebaseMoves: [TablebaseMove] = []
        for move in moves {
          let tablebaseMove = TablebaseMove(
            uci: move.uci, san: move.san, dtz: move.dtz, precise_dtz: move.precise_dtz,
            dtm: move.dtm, zeroing: move.zeroing, checkmate: move.checkmate,
            stalemate: move.stalemate, variant_win: move.variant_win,
            variant_loss: move.variant_loss, insufficient_material: move.insufficient_material,
            category: convertCategoryTablebaseJsonMoves(payload: move.category))
          tablebaseMoves.append(tablebaseMove)
        }
        tablebaseLookup.moves = tablebaseMoves
        return tablebaseLookup

      }
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func getAtomicTablebase(fen: String) {
    fatalError("getAtomicTablebase(fen: String) has not been implemented yet. Please file an issue")
  }

  public func getAntichessTablebase(fen: String) {
    fatalError(
      "getAntichessTablebase(fen: String) has not been implemented yet. Please file an issue")
  }

}
