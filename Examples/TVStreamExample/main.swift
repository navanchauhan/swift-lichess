import Foundation
import LichessClient

struct TVEvent: Decodable { let type: String?; let id: String? }

@main
struct App {
  static func main() async {
    let client = LichessClient()
    do {
      let body = try await client.streamTVFeed()
      var count = 0
      for try await evt in Streaming.ndjsonStream(from: body, as: TVEvent.self) {
        print("event:", evt.type ?? "?", "id:", evt.id ?? "-")
        count += 1
        if count >= 1 { break }
      }
    } catch {
      print("Error:", error)
    }
  }
}

