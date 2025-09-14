import Foundation
import LichessClient

@main
struct App {
  static func main() async {
    let client = LichessClient()
    do {
      let daily = try await client.getDailyPuzzle()
      print("Daily puzzle:", daily.puzzle.id, "rating:", daily.puzzle.rating)

      let byId = try await client.getPuzzle(id: daily.puzzle.id)
      print("By-ID perf:", byId.game.perf.name)

      let next = try await client.getNextPuzzle(angle: nil)
      print("Next puzzle:", next.puzzle.id)
    } catch {
      print("Error:", error)
    }
  }
}

