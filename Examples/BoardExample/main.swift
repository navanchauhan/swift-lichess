import Foundation
import LichessClient

@main
struct BoardExample {
  static func main() async {
    // Note: Most Board endpoints require an authenticated client with board/challenge scopes
    let client = LichessClient()
    do {
      // Stream a board game (replace with a valid game id you are playing)
      if let gameId = ProcessInfo.processInfo.environment["LICHESS_GAME_ID"], !gameId.isEmpty {
        let body = try await client.streamBoardGame(gameId: gameId)
        struct AnyJSON: Decodable {}
        var first = true
        for try await _ in Streaming.ndjsonStream(from: body, as: AnyJSON.self) {
          print("received board event")
          if first { break }
          first = false
        }
      }
    } catch {
      print("BoardExample error:", error)
    }
  }
}

