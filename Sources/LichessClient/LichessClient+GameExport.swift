import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: - Types

  public enum GameSingleFormat { case pgn, json }

  public struct GameJSON: Codable, Sendable {
    public let id: String
    public let moves: String?
  }

  public struct GameImportResult: Codable, Sendable { public let id: String?; public let url: String? }

  // MARK: - Single game export

  /// Export one game (PGN or JSON).
  public func exportGame(
    id: String,
    format: GameSingleFormat = .pgn,
    moves: Bool? = nil,
    pgnInJson: Bool? = nil,
    tags: Bool? = nil,
    clocks: Bool? = nil,
    evals: Bool? = nil,
    accuracy: Bool? = nil,
    opening: Bool? = nil,
    division: Bool? = nil,
    literate: Bool? = nil,
    withBookmarked: Bool? = nil
  ) async throws -> HTTPBody {
    let accept: [OpenAPIRuntime.AcceptHeaderContentType<Operations.gamePgn.AcceptableContentType>] = {
      switch format {
      case .pgn: return [.init(contentType: .application_x_hyphen_chess_hyphen_pgn)]
      case .json: return [.init(contentType: .json)]
      }
    }()
    let resp = try await underlyingClient.gamePgn(
      path: .init(gameId: id),
      query: .init(moves: moves, pgnInJson: pgnInJson, tags: tags, clocks: clocks, evals: evals, accuracy: accuracy, opening: opening, division: division, literate: literate, withBookmarked: withBookmarked),
      headers: .init(accept: accept)
    )
    switch resp { case .ok(let ok): return try ok.body.asHTTPBody(); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - User games export (PGN or NDJSON)

  public func exportUserGames(
    username: String,
    format: ExportFormat = .pgn,
    since: Int? = nil,
    until: Int? = nil,
    max: Int? = nil,
    vs: String? = nil,
    rated: Bool? = nil,
    color: String? = nil,
    analysed: Bool? = nil,
    moves: Bool? = nil,
    pgnInJson: Bool? = nil,
    tags: Bool? = nil,
    clocks: Bool? = nil,
    evals: Bool? = nil,
    accuracy: Bool? = nil,
    opening: Bool? = nil,
    division: Bool? = nil,
    ongoing: Bool? = nil,
    finished: Bool? = nil,
    literate: Bool? = nil,
    lastFen: Bool? = nil,
    withBookmarked: Bool? = nil,
    sort: String? = nil
  ) async throws -> HTTPBody {
    let accept: [OpenAPIRuntime.AcceptHeaderContentType<Operations.apiGamesUser.AcceptableContentType>] =
      format == .pgn ? [.init(contentType: .application_x_hyphen_chess_hyphen_pgn)] : [.init(contentType: .application_x_hyphen_ndjson)]
    let resp = try await underlyingClient.apiGamesUser(
      path: .init(username: username),
      query: .init(
        since: since, until: until, max: max, vs: vs, rated: rated,
        perfType: nil,
        color: color.flatMap { Operations.apiGamesUser.Input.Query.colorPayload(rawValue: $0) },
        analysed: analysed, moves: moves, pgnInJson: pgnInJson, tags: tags, clocks: clocks, evals: evals,
        accuracy: accuracy, opening: opening, division: division, ongoing: ongoing, finished: finished,
        literate: literate, lastFen: lastFen, withBookmarked: withBookmarked,
        sort: sort.flatMap { Operations.apiGamesUser.Input.Query.sortPayload(rawValue: $0) }
      ),
      headers: .init(accept: accept)
    )
    switch resp { case .ok(let ok): return try ok.body.asHTTPBody(); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - Export games by IDs (PGN/NDJSON)

  public func exportGamesByIds(
    ids: [String],
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
    let accept: [OpenAPIRuntime.AcceptHeaderContentType<Operations.gamesExportIds.AcceptableContentType>] =
      format == .pgn ? [.init(contentType: .application_x_hyphen_chess_hyphen_pgn)] : [.init(contentType: .application_x_hyphen_ndjson)]
    let bodyText = ids.joined(separator: "\n")
    let resp = try await underlyingClient.gamesExportIds(
      query: .init(moves: moves, pgnInJson: pgnInJson, tags: tags, clocks: clocks, evals: evals, accuracy: accuracy, opening: opening, division: division, literate: literate),
      headers: .init(accept: accept),
      body: .plainText(.init(bodyText))
    )
    switch resp { case .ok(let ok): return try ok.body.asHTTPBody(); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - Streaming by users / ids

  public func streamGamesByUsers(usernames: [String], withCurrentGames: Bool? = nil) async throws -> HTTPBody {
    let bodyText = usernames.joined(separator: "\n")
    let resp = try await underlyingClient.gamesByUsers(
      query: .init(withCurrentGames: withCurrentGames),
      headers: .init(),
      body: .plainText(.init(bodyText))
    )
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_ndjson; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func streamGamesByIds(streamId: String, ids: [String]) async throws -> HTTPBody {
    let resp = try await underlyingClient.gamesByIds(
      path: .init(streamId: streamId),
      headers: .init(),
      body: .plainText(.init(ids.joined(separator: "\n")))
    )
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_ndjson; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func addGamesToStream(streamId: String, ids: [String]) async throws -> Bool {
    let resp = try await underlyingClient.gamesByIdsAdd(
      path: .init(streamId: streamId),
      headers: .init(),
      body: .plainText(.init(ids.joined(separator: "\n")))
    )
    switch resp { case .ok: return true; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  // MARK: - Import / My imports / Bookmarks

  public func importGame(pgn: String) async throws -> GameImportResult {
    let resp = try await underlyingClient.gameImport(body: .urlEncodedForm(.init(pgn: pgn)))
    switch resp {
    case .ok(let ok):
      let payload = try ok.body.json
      return GameImportResult(id: payload.id, url: payload.url)
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  public func exportMyImportedGames() async throws -> HTTPBody {
    let resp = try await underlyingClient.apiImportedGamesUser()
    switch resp { case .ok(let ok): return try ok.body.application_x_hyphen_chess_hyphen_pgn; case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }

  public func exportBookmarkedGames(
    format: ExportFormat = .pgn,
    since: Int? = nil,
    until: Int? = nil,
    max: Int? = nil,
    moves: Bool? = nil,
    pgnInJson: Bool? = nil,
    tags: Bool? = nil,
    clocks: Bool? = nil,
    evals: Bool? = nil,
    accuracy: Bool? = nil,
    opening: Bool? = nil,
    division: Bool? = nil,
    literate: Bool? = nil,
    lastFen: Bool? = nil,
    sort: String? = nil
  ) async throws -> HTTPBody {
    let accept: [OpenAPIRuntime.AcceptHeaderContentType<Operations.apiExportBookmarks.AcceptableContentType>] =
      format == .pgn ? [.init(contentType: .application_x_hyphen_chess_hyphen_pgn)] : [.init(contentType: .application_x_hyphen_ndjson)]
    let resp = try await underlyingClient.apiExportBookmarks(
      query: .init(since: since, until: until, max: max, moves: moves, pgnInJson: pgnInJson, tags: tags, clocks: clocks, evals: evals, accuracy: accuracy, opening: opening, division: division, literate: literate, lastFen: lastFen, sort: sort.flatMap { Operations.apiExportBookmarks.Input.Query.sortPayload(rawValue: $0) }),
      headers: .init(accept: accept)
    )
    switch resp { case .ok(let ok): return try ok.body.asHTTPBody(); case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s) }
  }
}

private extension Operations.gamePgn.Output.Ok.Body {
  func asHTTPBody() throws -> HTTPBody {
    switch self {
    case .application_x_hyphen_chess_hyphen_pgn(let b): return b
    case .json(let j):
      let data = try JSONEncoder().encode(j)
      return HTTPBody(data)
    }
  }
}

private extension Operations.apiGamesUser.Output.Ok.Body {
  func asHTTPBody() throws -> HTTPBody {
    switch self {
    case .application_x_hyphen_chess_hyphen_pgn(let b): return b
    case .application_x_hyphen_ndjson(let b): return b
    }
  }
}

private extension Operations.gamesExportIds.Output.Ok.Body {
  func asHTTPBody() throws -> HTTPBody {
    switch self {
    case .application_x_hyphen_chess_hyphen_pgn(let b): return b
    case .application_x_hyphen_ndjson(let b): return b
    }
  }
}

private extension Operations.apiExportBookmarks.Output.Ok.Body {
  func asHTTPBody() throws -> HTTPBody {
    switch self {
    case .application_x_hyphen_chess_hyphen_pgn(let b): return b
    case .application_x_hyphen_ndjson(let b): return b
    }
  }
}
