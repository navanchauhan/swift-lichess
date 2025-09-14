import Foundation

extension LichessClient {
  public struct Timeline: Sendable, Hashable {
    public let entries: [Entry]
    public let users: [String: TimelineUser]
  }
  public struct TimelineUser: Sendable, Hashable { public let id: String; public let name: String; public let title: String?; public let flair: String?; public let patron: Bool? }

  public enum Entry: Sendable, Hashable {
    case follow(String, String)
    case teamJoin(String, String)
    case teamCreate(String, String)
    case forumPost(String, String, String)
    case blogPost(String, String)
    case ublogPost(String, String, String)
    case tourJoin(String, String, String)
    case gameEnd(String, String, String, Bool)
    case simulCreate(String, String, String)
    case simulJoin(String, String, String)
    case studyLike(String, String, String)
    case planStart(String)
    case planRenew(String)
    case ublogPostLike(String, String, String)
    case streamStart(String, String?)
    case unknown(String)
  }

  /// Get the logged-in user's timeline.
  public func getTimeline(since: Int? = nil, nb: Int? = nil) async throws -> Timeline {
    let resp = try await underlyingClient.timeline(query: .init(since: since, nb: nb))
    switch resp {
    case .ok(let ok):
      let json = try ok.body.json
      var mapped: [Entry] = []
      for any in json.entries { mapped.append(mapTimelineEntry(any)) }
      var users: [String: TimelineUser] = [:]
      for (k, v) in json.users.additionalProperties {
        users[k] = TimelineUser(id: v.id, name: v.name, title: v.title?.rawValue, flair: v.flair, patron: v.patron)
      }
      return Timeline(entries: mapped, users: users)
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }

  private func mapTimelineEntry(_ any: Components.Schemas.Timeline.entriesPayloadPayload) -> Entry {
    if let e = any.value1 { return .follow(e.data.u1, e.data.u2) }
    if let e = any.value2 { return .teamJoin(e.data.userId, e.data.teamId) }
    if let e = any.value3 { return .teamCreate(e.data.userId, e.data.teamId) }
    if let e = any.value4 { return .forumPost(e.data.userId, e.data.topicId, e.data.topicName) }
    if let e = any.value5 { return .blogPost("", e.data.id) }
    if let e = any.value6 { return .ublogPost(e.data.userId, e.data.id, e.data.title) }
    if let e = any.value7 { return .tourJoin(e.data.userId, e.data.tourId, e.data.tourName) }
    if let e = any.value8 { return .gameEnd(e.data.fullId, e.data.perf.rawValue, e.data.opponent, e.data.win) }
    if let e = any.value9 { return .simulCreate(e.data.userId, e.data.simulId, e.data.simulName) }
    if let e = any.value10 { return .studyLike(e.data.userId, e.data.studyId, e.data.studyName) }
    if let e = any.value11 { return .planStart(e.data.userId) }
    if let e = any.value12 { return .planRenew(e.data.userId) }
    if let e = any.value13 { return .ublogPostLike(e.data.userId, e.data.id, e.data.title) }
    if let e = any.value14 { return .streamStart(e.data.id, e.data.title) }
    return .unknown("?")
  }
}
