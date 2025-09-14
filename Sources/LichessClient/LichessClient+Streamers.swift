import Foundation

extension LichessClient {
  public struct LiveStreamer: Codable, Sendable, Hashable {
    public let id: String
    public let name: String?
    public let headline: String?
    public let description: String?
    public let service: String?
    public let status: String?
    public let lang: String?
    public let twitch: String?
    public let youTube: String?
    public let image: String?
  }

  /// Get live streamers currently broadcasting on Lichess.
  public func getLiveStreamers() async throws -> [LiveStreamer] {
    let resp = try await underlyingClient.streamerLive()
    switch resp {
    case .ok(let ok):
      let rows = try ok.body.json
      return rows.map { row in
        let u = row.value1
        let info = row.value2
        return LiveStreamer(
          id: u.id,
          name: info.streamer?.name,
          headline: info.streamer?.headline,
          description: info.streamer?.description,
          service: info.stream?.service?.rawValue,
          status: info.stream?.status,
          lang: info.stream?.lang,
          twitch: info.streamer?.twitch,
          youTube: info.streamer?.youTube,
          image: info.streamer?.image
        )
      }
    case .undocumented(let status, _):
      throw LichessClientError.undocumentedResponse(statusCode: status)
    }
  }
}
