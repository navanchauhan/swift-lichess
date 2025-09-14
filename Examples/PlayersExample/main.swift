import Foundation
import LichessClient

struct App {
  static func main() async {
    let client = LichessClient()
    do {
      let top = try await client.getAllTop10()
      print("Bullet top count:", top["bullet"]?.count ?? 0)

      let blitz100 = try await client.getLeaderboard(perfType: "blitz", nb: 5)
      if let first = blitz100.first {
        print("Top Blitz:", first.username, first.rating)
      }
    } catch {
      print("Error:", error)
    }
  }
}

