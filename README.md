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

