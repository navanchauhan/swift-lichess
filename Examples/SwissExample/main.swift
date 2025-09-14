import Foundation
import LichessClient

struct SwissExample {
  static func main() async {
    let client = LichessClient()
    do {
      // Replace with a real swiss id to try locally
      _ = try await client.getTeamSwissTournaments(teamId: "lichess", max: 1)
      print("Fetched team swiss NDJSON stream")
    } catch {
      print("SwissExample error: \(error)")
    }
  }
}

