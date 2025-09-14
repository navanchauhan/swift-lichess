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

## OAuth / PKCE

```swift
import LichessClient

let pkce = LichessClient.generatePKCE()
let state = UUID().uuidString
let redirect = URL(string: "myapp://callback")!

// 1) Send user to this URL (open in browser / webview)
let authURL = LichessClient().buildAuthorizationURL(
  clientID: "myapp",
  redirectURI: redirect,
  scopes: ["challenge:write", "email:read"],
  state: state,
  pkce: pkce
)

// 2) Handle redirect back to your app and extract the `code`
// let code = ...

// 3) Exchange code for token
let token = try await LichessClient().exchangeCodeForToken(
  clientID: "myapp",
  code: code,
  redirectURI: redirect,
  codeVerifier: pkce.codeVerifier
)

// 4) Create an authenticated client
let authed = LichessClient(accessToken: token.accessToken)
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
