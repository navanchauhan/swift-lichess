import Foundation
import LichessClient

struct App {
  static func main() async {
    let client = LichessClient()
    do {
      let ct = try await client.getCrosstable(user1: "drnykterstein", user2: "rebeccaharris")
      print("games=\(ct.nbGames) scores=\(ct.scores)")
    } catch {
      print("Error:", error)
    }
  }
}

