import Foundation
import LichessClient

struct App {
  static func main() async {
    let client = LichessClient()
    do {
      let live = try await client.getLiveStreamers()
      print(live.prefix(5))
    } catch {
      print("Error:", error)
    }
  }
}

