import Foundation
import LichessClient

struct PuzzlesRacerExample {
  static func main() async {
    let client = LichessClient()
    do {
      // Stream your puzzle activity (NDJSON)
      let body = try await client.getPuzzleActivity(max: 1)
      struct Item: Decodable { let win: Bool? }
      for try await it in Streaming.ndjsonStream(from: body, as: Item.self) { print(it.win ?? false); break }

      // Puzzle replay summary for 30 days in theme "fork"
      let replay = try await client.getPuzzleReplay(days: 30, theme: "fork")
      print(replay?.remaining.count ?? 0)

      // Create a racer and fetch its results
      let racer = try await client.createRacer()
      let results = try await client.getRacer(id: racer.id)
      print(racer.id, results?.players.count ?? 0)
    } catch {
      print("PuzzlesRacerExample error: \(error)")
    }
  }
}

