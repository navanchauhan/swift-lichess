import Foundation
import LichessClient

@main
struct GameExportExample {
  static func main() async {
    let client = LichessClient()
    do {
      let body = try await client.exportUserGames(username: "thibault", format: .pgn, max: 5, moves: true)
      var count = 0
      for try await _ in body { count += 1 }
      print("Exported entries stream chunks: \(count)")
    } catch {
      print("GameExportExample error: \(error)")
    }
  }
}

