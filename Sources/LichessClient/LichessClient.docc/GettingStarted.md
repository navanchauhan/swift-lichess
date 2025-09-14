# Getting Started

Learn how to add Swift‑Lichess to your project and make a first request.

## Add the dependency

Add the package to your `Package.swift` or Xcode project:

```swift
dependencies: [
  .package(url: "https://github.com/navanchauhan/swift-lichess", from: "0.1.0"),
]
```

Then add the library product to your target:

```swift
.target(
  name: "MyApp",
  dependencies: ["LichessClient"]
)
```

## Create a client

```swift
import LichessClient

let client = LichessClient() // unauthenticated
```

To authenticate, provide a personal access token. See <doc:Authentication>.

## Fetch data

Look up a public profile:

```swift
let user = try await client.getUser(username: "thibault")
print(user.username, user.title ?? "-")
```

List the top broadcasts:

```swift
let top = try await client.getTopBroadcasts(page: 1)
print(top.active.count)
```

Stream an NDJSON feed and decode items as they arrive:

```swift
let body = try await client.streamIncomingEvents()
struct Event: Decodable { let type: String }
for try await e in Streaming.ndjsonStream(from: body, as: Event.self) {
  print(e.type)
}
```

Continue with <doc:Endpoints> for an overview of the available API areas.

