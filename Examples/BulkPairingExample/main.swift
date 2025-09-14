import Foundation
import LichessClient

struct BulkPairingExample {
  static func main() async {
    // Note: These endpoints require an authenticated client with `challenge:write` scope.
    // Provide a token via configuration, e.g. LichessClient(accessToken: "...")
    let client = LichessClient()
    do {
      // List existing bulk pairings (for the authenticated user)
      let bulks = try await client.listBulkPairings()
      print("Your bulks:", bulks.map(\.id))

      // Export games from a bulk (PGN or NDJSON)
      if let first = bulks.first {
        _ = try await client.exportBulkPairingGames(id: first.id, format: .pgn, moves: true)
        print("Requested PGN export for bulk:", first.id)
      }
    } catch {
      print("BulkPairingExample error:", error)
    }
  }
}
