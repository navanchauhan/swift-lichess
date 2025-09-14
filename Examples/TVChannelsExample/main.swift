import Foundation
import LichessClient

struct App {
  static func main() async {
    let client = LichessClient()
    do {
      let channels = try await client.getTVChannels()
      for (channel, game) in channels.entries {
        print("\(channel.rawValue): \(game.user.name) (\(game.rating)) id=\(game.gameId) color=\(game.color)")
      }

      // Fetch a few Blitz games in PGN
      let body = try await client.getTVChannelGames(channel: "blitz", format: .pgn, nb: 3)
      let pgn = try await String(collecting: body, upTo: 4096)
      print("Sample PGN first chars:\n", pgn.prefix(120))
    } catch {
      print("Error:", error)
    }
  }
}

