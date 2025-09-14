import Foundation
import LichessClient

struct AccountExample {
  static func main() async {
    let client = LichessClient()
    do {
      let prefs = try await client.getMyPreferences()
      print("Lang:", prefs.language ?? "-", "Dark:", prefs.dark ?? false)
      let games = try await client.getMyOngoingGames(nb: 3)
      print("Ongoing:", games.count)
    } catch {
      print("AccountExample error: \(error)")
    }
  }
}

