# Swift-Lichess

API Client for Lichess. The end goal of this package is to implement everything listed in the OpenAPI Reference (2.0.0)

## Example

```swift
import LichessClient

let client = LichessClient()

Task {
    do {
        let tournaments = try await client.broadcastIndex(nb: 10)
    } catch {
        print("Error fetching tournaments: \(error)")
    }
}
```

## Configuration, Transport, and Auth

```swift
import LichessClient

// Provide an access token and custom headers via middlewares
let client = LichessClient(configuration: .init(
  accessToken: "<your PAT>",
  userAgent: "swift-lichess/1.0 (+https://github.com/navanchauhan/swift-lichess)",
  maxConcurrentRequests: 4,
  retryPolicy: .init(maxAttempts: 3),
  // You can also pass a custom transport and additional middlewares
  // transport: MyCustomTransport(),
  // middlewares: [MyMiddleware()]
))
```
