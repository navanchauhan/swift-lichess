# Streams

Many Lichess endpoints return NDJSON or PGN streams. Use ``Streaming``
helpers to iterate items incrementally without loading the whole body.

## NDJSON

```swift
let body = try await client.streamIncomingEvents()
struct Event: Decodable { let type: String }
for try await e in Streaming.ndjsonStream(from: body, as: Event.self) {
  print(e.type)
}
```

## PGN

```swift
let pgn = try await client.exportGame(id: "abcdefgh", format: .pgn)
for try await chunk in pgn { 
  // handle data chunk
}
```

For more stream examples, see the README and endpoint‑specific docs.

