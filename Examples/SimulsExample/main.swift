import Foundation
import LichessClient

@main
struct App {
  static func main() async {
    let client = LichessClient()
    do {
      let s = try await client.getSimuls()
      print("created=\(s.created.count) started=\(s.started.count)")
    } catch {
      print("Error:", error)
    }
  }
}

