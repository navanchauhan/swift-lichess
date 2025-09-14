import XCTest
@testable import LichessClient
import OpenAPIRuntime

final class StreamingTests: XCTestCase {

  struct Item: Codable, Equatable { let a: Int }

  func testDecodeTwoItems() async throws {
    let ndjson = "{" + "\"a\":1}" + "\n{" + "\"a\":2}" + "\n"
    let body = HTTPBody(ndjson)
    var received: [Item] = []
    for try await item in Streaming.ndjsonStream(from: body, as: Item.self) {
      received.append(item)
    }
    XCTAssertEqual(received, [Item(a: 1), Item(a: 2)])
  }

  func testCancellationStopsConsumer() async throws {
    // Build a slow NDJSON producer
    let stream = AsyncStream(HTTPBody.ByteChunk.self) { continuation in
      continuation.yield(ArraySlice("{\"a\":1}\n".utf8))
      // then produce many more lines slowly on a detached task
      Task.detached {
        for i in 2...1000 {
          try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
          continuation.yield(ArraySlice("{\"a\":\(i)}\n".utf8))
        }
        continuation.finish()
      }
    }
    let body = HTTPBody(stream, length: .unknown)
    let streamSeq = Streaming.ndjsonStream(from: body, as: Item.self)

    // Consume first two items, then cancel
    var count = 0
    let consumer = Task {
      for try await _ in streamSeq {
        count += 1
        if count == 2 { break }
      }
    }
    try await consumer.value
    let before = count
    // wait a bit to see if more items accumulate despite we stopped consuming
    try await Task.sleep(nanoseconds: 120_000_000)
    XCTAssertEqual(count, before)
  }
}

