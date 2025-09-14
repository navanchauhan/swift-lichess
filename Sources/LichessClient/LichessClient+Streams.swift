//
//  LichessClient+Streams.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  /// Stream positions and moves of any ongoing game as NDJSON.
  /// Returns the raw NDJSON HTTPBody; use `Streaming.ndjsonStream` to decode lines.
  public func streamGame(gameId: String) async throws -> HTTPBody {
    let response = try await underlyingClient.streamGame(
      .init(path: .init(id: gameId))
    )
    switch response {
    case .ok(let okResponse):
      return try okResponse.body.application_x_hyphen_ndjson
    case .tooManyRequests:
      throw LichessClientError.undocumentedResponse(statusCode: 429)
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }

  /// Stream positions and moves of the current TV game as NDJSON.
  /// Returns the raw NDJSON HTTPBody; use `Streaming.ndjsonStream` to decode lines.
  public func streamTVFeed() async throws -> HTTPBody {
    let response = try await underlyingClient.tvFeed(.init())
    switch response {
    case .ok(let okResponse):
      return try okResponse.body.application_x_hyphen_ndjson
    case .undocumented(let statusCode, _):
      throw LichessClientError.undocumentedResponse(statusCode: statusCode)
    }
  }
}
