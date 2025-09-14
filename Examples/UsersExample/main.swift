import Foundation
import LichessClient

struct UsersExample {
  static func main() async {
    let client = LichessClient()
    do {
      // Bulk users
      let users = try await client.getUsers(usernames: ["thibault","lichess"])
      print(users.map(\.username))

      // Status
      let status = try await client.getUsersStatus(ids: ["thibault","lichess"])
      print(status.map { ($0.name, $0.online == true) })

      // Current game (PGN)
      _ = try await client.getUserCurrentGame(username: "thibault", format: .pgn, moves: true)
    } catch {
      print("UsersExample error: \(error)")
    }
  }
}

