import Foundation
import OpenAPIRuntime

public enum Streaming {

  /// Decode an HTTPBody containing Newline-Delimited JSON (NDJSON) into a typed AsyncThrowingStream.
  /// The returned stream supports cancellation; cancelling the consumer task cancels the decoding task.
  public static func ndjsonStream<T: Decodable>(
    from body: HTTPBody,
    as type: T.Type = T.self,
    decoder: JSONDecoder = .init()
  ) -> AsyncThrowingStream<T, Error> {
    let sequence = body.asDecodedJSONLines(of: T.self, decoder: decoder)
    return AsyncThrowingStream(T.self) { continuation in
      let task = Task {
        do {
          for try await event in sequence {
            if Task.isCancelled { break }
            continuation.yield(event)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}

