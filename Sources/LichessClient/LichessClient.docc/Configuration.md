# Configuration

Customize transport, headers, logging, retries, and more.

## Client configuration

The ``LichessClient/Configuration`` type lets you override defaults:

```swift
let cfg = LichessClient.Configuration(
  serverURL: URL(string: "https://lichess.org")!,
  tablebaseServerURL: URL(string: "https://tablebase.lichess.ovh")!,
  transport: URLSessionTransport(),
  middlewares: [
    LoggingMiddleware(configuration: .init(enabled: true, level: .info)),
    RetryMiddleware(policy: .init(maxAttempts: 3)),
    RateLimitMiddleware(policy: .init(maxRetries: 2)),
  ],
  logging: .init(enabled: true, level: .debug, logBodies: false),
  accessToken: "<token>",
  userAgent: "swift-lichess/1.0 (+https://github.com/navanchauhan/swift-lichess)",
  maxConcurrentRequests: 4
)

let client = LichessClient(configuration: cfg)
```

## Middlewares

- ``LoggingMiddleware`` and ``LoggingConfiguration`` to print requests/responses.
- ``RetryMiddleware`` and ``RetryPolicy`` for exponential backoff.
- ``RateLimitMiddleware`` and ``RateLimitPolicy`` to respect `429` responses.
- ``TokenAuthMiddleware`` to add a bearer token.
- ``UserAgentMiddleware`` to set a custom user‑agent.
- ``ConcurrencyLimitMiddleware`` to bound concurrent requests.

