import Foundation
import LichessClient

struct App {
  static func main() async {
    let client = LichessClient()
    do {
      let fen = "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3"
      if let eval = try await client.getCloudEval(fen: fen, multiPv: 3) {
        print("depth=\(eval.depth) knodes=\(eval.knodes)")
        if let best = eval.pvs.first { print("best:", best.moves.prefix(5).joined(separator: " ")) }
      } else {
        print("No cloud eval for position")
      }
    } catch {
      print("Error:", error)
    }
  }
}

