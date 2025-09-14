import Foundation
import LichessClient

@main
struct ChallengesExample {
  static func main() async {
    let client = LichessClient()
    do {
      // List current challenges
      let list = try await client.listChallenges()
      print("incoming=\(list.incoming.count) outgoing=\(list.outgoing.count)")
    } catch {
      print("ChallengesExample error:", error)
    }
  }
}

