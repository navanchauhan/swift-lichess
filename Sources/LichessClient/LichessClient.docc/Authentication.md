# Authentication

Use a personal access token to access endpoints that require auth.

## Create an authenticated client

```swift
import LichessClient

let client = LichessClient(accessToken: "<token>")
```

Alternatively, pass the token via configuration to add more options:

```swift
let authed = LichessClient(configuration: .init(
  accessToken: "<token>",
  userAgent: "swift-lichess/1.0 (+https://github.com/navanchauhan/swift-lichess)",
  retryPolicy: .init(maxAttempts: 3),
  maxConcurrentRequests: 4
))
```

## PKCE (OAuth)

Swift‑Lichess also provides helpers to implement the PKCE flow:

```swift
let pkce = LichessClient.generatePKCE()
let redirect = URL(string: "myapp://callback")!
let authURL = LichessClient().buildAuthorizationURL(
  clientID: "myapp",
  redirectURI: redirect,
  scopes: ["challenge:write", "email:read"],
  state: UUID().uuidString,
  pkce: pkce
)
// After receiving the redirect with a `code`:
let token = try await LichessClient().exchangeCodeForToken(
  clientID: "myapp", code: code, redirectURI: redirect, codeVerifier: pkce.codeVerifier
)
```

For scopes and token creation, consult the Lichess documentation.

