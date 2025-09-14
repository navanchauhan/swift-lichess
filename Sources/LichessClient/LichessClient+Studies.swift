//
//  LichessClient+Studies.swift
//

import Foundation
import OpenAPIRuntime

extension LichessClient {
  // MARK: Types
  public struct StudyImportPlayer: Codable {
    public let name: String?
    public let rating: Int?
  }

  public struct StudyImportChapter: Codable {
    public let id: String?
    public let name: String?
    public let players: [StudyImportPlayer]?
    public let status: String?
  }

  public struct StudyImportResult: Codable {
    public let chapters: [StudyImportChapter]
  }

  // MARK: Exports
  public func getStudyChapterPGN(
    studyId: String,
    chapterId: String,
    clocks: Bool? = nil,
    comments: Bool? = nil,
    variations: Bool? = nil,
    orientation: Bool? = nil
  ) async throws -> HTTPBody {
    let response = try await underlyingClient.studyChapterPgn(
      path: .init(studyId: studyId, chapterId: chapterId),
      query: .init(clocks: clocks, comments: comments, variations: variations, orientation: orientation)
    )
    switch response {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_chess_hyphen_pgn
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func getStudyPGN(
    studyId: String,
    clocks: Bool? = nil,
    comments: Bool? = nil,
    variations: Bool? = nil,
    orientation: Bool? = nil
  ) async throws -> HTTPBody {
    let response = try await underlyingClient.studyAllChaptersPgn(
      path: .init(studyId: studyId),
      query: .init(clocks: clocks, comments: comments, variations: variations, orientation: orientation)
    )
    switch response {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_chess_hyphen_pgn
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func getUserStudiesPGN(
    username: String,
    clocks: Bool? = nil,
    comments: Bool? = nil,
    variations: Bool? = nil,
    orientation: Bool? = nil
  ) async throws -> HTTPBody {
    let response = try await underlyingClient.studyExportAllPgn(
      path: .init(username: username),
      query: .init(clocks: clocks, comments: comments, variations: variations, orientation: orientation)
    )
    switch response {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_chess_hyphen_pgn
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  public func listUserStudiesMetadata(username: String) async throws -> HTTPBody {
    let response = try await underlyingClient.studyListMetadata(path: .init(username: username))
    switch response {
    case .ok(let ok):
      return try ok.body.application_x_hyphen_ndjson
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: Import
  public func importPGNIntoStudy(
    studyId: String,
    pgn: String,
    name: String? = nil,
    orientation: String? = nil,
    variant: String? = nil
  ) async throws -> StudyImportResult {
    let orient = orientation.flatMap { o -> Operations.apiStudyImportPGN.Input.Body.urlEncodedFormPayload.orientationPayload? in
      switch o.lowercased() {
      case "white": return .white
      case "black": return .black
      default: return nil
      }
    }
    let variantKey = variant.flatMap { Components.Schemas.VariantKey(rawValue: $0) }
    let body = Operations.apiStudyImportPGN.Input.Body.urlEncodedForm(
      .init(pgn: pgn, name: name, orientation: orient, variant: variantKey)
    )
    let response = try await underlyingClient.apiStudyImportPGN(path: .init(studyId: studyId), body: body)
    switch response {
    case .ok(let ok):
      let payload = try ok.body.json
      let chapters: [StudyImportChapter] = (payload.chapters ?? []).map { ch in
        let players = ch.players?.map { StudyImportPlayer(name: $0.name, rating: $0.rating) }
        return StudyImportChapter(id: ch.id, name: ch.name, players: players, status: ch.status)
      }
      return StudyImportResult(chapters: chapters)
    case .badRequest(let bad):
      // Bubble up server-provided error message if available
      // Parse generic error container
      throw LichessClientError.parsingError(error: NSError(domain: "study.import", code: 400, userInfo: ["message": String(describing: bad)]))
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  // MARK: - Maintenance
  /// Delete a study chapter. Requires appropriate permissions on the study.
  @discardableResult
  public func deleteStudyChapter(studyId: String, chapterId: String) async throws -> Bool {
    let resp = try await underlyingClient.apiStudyStudyIdChapterIdDelete(path: .init(studyId: studyId, chapterId: chapterId))
    switch resp {
    case .noContent: return true
    case .undocumented(let s, _): throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }

  /// HEAD request for the whole-study PGN to get Last-Modified.
  /// - Returns: The `Last-Modified` header parsed as `Date` if present.
  public func getStudyPGNLastModified(studyId: String) async throws -> Date? {
    let resp = try await underlyingClient.studyAllChaptersHead(path: .init(studyId: studyId))
    switch resp {
    case .noContent(let nc):
      if let lm = nc.headers.Last_hyphen_Modified {
        return Self.parseHTTPDate(lm)
      }
      return nil
    case .undocumented(let s, _):
      throw LichessClientError.undocumentedResponse(statusCode: s)
    }
  }
}

private extension LichessClient {
  static func parseHTTPDate(_ s: String) -> Date? {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.timeZone = TimeZone(secondsFromGMT: 0)
    fmt.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    return fmt.date(from: s)
  }
}
