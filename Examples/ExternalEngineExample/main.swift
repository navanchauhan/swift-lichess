import Foundation
import LichessClient

struct ExternalEngineExample {
  static func main() async {
    let client = LichessClient()
    do {
      // List engines (requires auth)
      let engines = try await client.listExternalEngines()
      print("Engines:", engines.map(\.name))

      // Analyse with external engine (NDJSON)
      if let e = engines.first {
        let common = LichessClient.ExternalEngineWorkCommon(
          sessionId: UUID().uuidString,
          threads: min(1, e.maxThreads),
          hash: min(16, e.maxHash),
          multiPv: 1,
          variant: "chess",
          initialFEN: "startpos",
          moves: []
        )
        let body = try await client.analyseWithExternalEngine(
          id: e.id,
          clientSecret: e.clientSecret,
          work: .depth(ply: 5, common: common)
        )
        struct AnyJSON: Decodable {}
        for try await _ in Streaming.ndjsonStream(from: body, as: AnyJSON.self) { break }
        print("analysis request sent")
      }
    } catch {
      print("ExternalEngineExample error:", error)
    }
  }
}
