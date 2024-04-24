//
//  LichessClient+Broadcasts.swift
//
//
//  Created by Navan Chauhan on 4/24/24.
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  public struct TournamentResponse: Codable, Identifiable {
    public let id: String
    public let tour: Tournament
    public let rounds: [Round]

    public init(from decoder: Decoder) throws {
      let container: KeyedDecodingContainer<LichessClient.TournamentResponse.CodingKeys> =
        try decoder.container(keyedBy: LichessClient.TournamentResponse.CodingKeys.self)
      self.tour = try container.decode(
        LichessClient.Tournament.self, forKey: LichessClient.TournamentResponse.CodingKeys.tour)
      self.rounds = try container.decode(
        [LichessClient.Round].self, forKey: LichessClient.TournamentResponse.CodingKeys.rounds)
      self.id = tour.id
    }
  }

  public struct Tournament: Codable {
    public let id: String
    public let name: String
    public let slug: String
    public let description: String
    public let markup: String?
    public let url: String?
  }

  public struct Round: Codable, Identifiable {
    public let id: String
    public let name: String
    public let slug: String
    public let startsAt: Date  // UNIX Epoch?
    public let finished: Bool?
    public let ongoing: Bool?

  }

  public struct Player: Codable {
    public let userId: String
    public let name: String
    public let color: String
  }

  public func broadcastIndex(nb: Int = 20) async throws -> AsyncThrowingMapSequence<
    JSONLinesDeserializationSequence<HTTPBody>, LichessClient.TournamentResponse
  > {
    let response = try await underlyingClient.broadcastIndex(query: .init(nb: nb))
    switch response {
    case .ok(let okResponse):
      let tournaments = try okResponse.body.application_x_hyphen_ndjson.asDecodedJSONLines(
        of: TournamentResponse.self)
      return tournaments
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func broadcastRound(
    broadcastTournamentSlug: String = "-", broadcastRoundSlug: String = "-",
    broadcastRoundId: String
  ) async throws {
    let response = try await underlyingClient.broadcastRoundGet(
      path: .init(
        broadcastTournamentSlug: broadcastTournamentSlug,
        broadcastRoundSlug: broadcastRoundSlug,
        broadcastRoundId: broadcastRoundId
      ))
    switch response {
    case .ok(let okResponse):
      print(okResponse.body, try okResponse.body.json)
    // TODO: Return
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func getBroadcastRoundPGN(broadcastRoundId: String) async throws -> HTTPBody {
    let response = try await underlyingClient.broadcastRoundPgn(
      path: .init(
        broadcastRoundId: broadcastRoundId
      ))

    switch response {
    case .ok(let okResponse):
      return try okResponse.body.application_x_hyphen_chess_hyphen_pgn
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  public func broadcastStreamRoundPgn(broadcastRoundId: String) async throws -> HTTPBody {
    let response = try await underlyingClient.broadcastStreamRoundPgn(
      path: .init(broadcastRoundId: broadcastRoundId))
    switch response {
    case .ok(let okResponse):
      return try okResponse.body.application_x_hyphen_chess_hyphen_pgn
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }
}
