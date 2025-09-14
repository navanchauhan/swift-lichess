import Foundation
import LichessClient

struct ArenaTournamentsExample {
  static func main() async {
    let client = LichessClient()
    do {
      let page = try await client.getCurrentTournaments()
      print("Created:", page.created.count, "Started:", page.started.count)
    } catch {
      print("ArenaTournamentsExample error: \(error)")
    }
  }
}

