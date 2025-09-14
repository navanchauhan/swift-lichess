import Foundation
import LichessClient

struct BotExample {
  static func main() async {
    let client = LichessClient()
    do {
      // Stream online bots (first item then stop)
      let body = try await client.streamOnlineBots()
      struct AnyJSON: Decodable {}
      for try await _ in Streaming.ndjsonStream(from: body, as: AnyJSON.self) {
        print("online bot item"); break
      }
    } catch {
      print("BotExample error:", error)
    }
  }
}

