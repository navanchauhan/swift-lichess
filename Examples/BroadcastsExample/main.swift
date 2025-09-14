import Foundation
import LichessClient

struct BroadcastsExample {
  static func main() async {
    let client = LichessClient()
    do {
      let top = try await client.getTopBroadcasts(page: 1)
      print("Active broadcasts: \(top.active.count)")
      if let past = top.past {
        print("Past page \(past.currentPage) results: \(past.results.count)")
      }
    } catch {
      print("BroadcastsExample error: \(error)")
    }
  }
}

