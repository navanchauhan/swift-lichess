import Foundation
import LichessClient

struct TeamsExample {
  static func main() async {
    let client = LichessClient()
    do {
      // Fetch popular teams (page 1)
      let page = try await client.getPopularTeams(page: 1)
      print("Popular teams page=\(page.currentPage) count=\(page.results.count)")

      // Fetch teams of a known user
      let mine = try await client.getTeams(of: "thibault")
      print("thibault teams (first):", mine.first?.name ?? "-")

      // Stream arena tournaments of a team (first item then stop)
      // Note: Replace "lichess" with a valid team id if needed.
      if let body = try? await client.streamTeamArena(teamId: "lichess", max: 1) {
        struct AnyJSON: Decodable {}
        var first = true
        for try await _ in Streaming.ndjsonStream(from: body, as: AnyJSON.self) {
          print("received arena tournament item")
          if first { break }
          first = false
        }
      }
    } catch {
      print("TeamsExample error: \(error)")
    }
  }
}

