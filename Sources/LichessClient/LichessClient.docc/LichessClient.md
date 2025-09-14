# LichessClient

A typed, async Swift client for the public Lichess HTTP API.

## Overview

Swift‑Lichess wraps the generated bindings from the official Lichess OpenAPI
specification with a small, ergonomic surface that feels at home in Swift.

- 100% endpoint coverage via generated bindings and thin wrappers
- Async/await, `HTTPBody` streams, and strict concurrency
- Pluggable middlewares for logging, retries, rate limiting, auth, and more

Create a client with default settings using ``LichessClient/init()`` or provide
custom ``LichessClient/Configuration`` to tailor transport, headers, policies,
and authentication.

### Quick Start

```swift
import LichessClient

let client = LichessClient()
let user = try await client.getUser(username: "thibault")
print(user.username)
```

For more guided examples, see <doc:GettingStarted> and <doc:Authentication>.

## Topics

### Essentials

- ``LichessClient``
- ``LichessClient/Configuration``
- ``LichessClient/LichessClientError``

### Middlewares

- ``LoggingMiddleware``
- ``RetryMiddleware``
- ``RateLimitMiddleware``
- ``ConcurrencyLimitMiddleware``
- ``TokenAuthMiddleware``
- ``UserAgentMiddleware``
- ``LoggingConfiguration``
- ``RetryPolicy``
- ``RateLimitPolicy``
- ``AsyncSemaphore``

### Guides

- <doc:GettingStarted>
- <doc:Authentication>
- <doc:Configuration>
- <doc:Streams>
- <doc:Endpoints>

