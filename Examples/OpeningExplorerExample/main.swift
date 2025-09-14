import Foundation
import LichessClient

struct OpeningExplorerExample {
  static func main() async {
    let client = LichessClient()
    do {
      // Masters DB lookup
      let masters = try await client.getOpeningExplorerMasters(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        moves: 5,
        topGames: 1
      )
      print("Masters moves:", masters.moves.prefix(3).map(\.san))

      // Fetch PGN of a masters game (replace with a real game id)
      let pgnBody = try await client.getOpeningExplorerMastersGamePGN(gameId: "<masters-game-id>")
      var printedFirstLine = false
      for try await chunk in pgnBody {
        if !printedFirstLine {
          print(String(decoding: chunk, as: UTF8.self).split(separator: "\n").first ?? "-")
          printedFirstLine = true
        }
        break
      }
    } catch {
      print("OpeningExplorerExample error: \(error)")
    }
  }
}

