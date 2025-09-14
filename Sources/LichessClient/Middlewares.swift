import Foundation
import OpenAPIRuntime
import HTTPTypes

/// Configuration for ``LoggingMiddleware``.
public struct LoggingConfiguration: Sendable {
  public enum Level: String, Sendable { case info, debug }
  public var enabled: Bool
  public var level: Level
  public var logBodies: Bool
  public var redactHeaders: [HTTPField.Name]
  public var sink: @Sendable (String) -> Void
  /// Create a logging configuration.
  /// - Parameters:
  ///   - enabled: When `true`, requests and responses are logged.
  ///   - level: Log level tag included in messages.
  ///   - logBodies: When `true`, bodies are logged in a redacted/preview form.
  ///   - redactHeaders: Header names to redact in logs (e.g. `.authorization`).
  ///   - sink: Destination for log lines, defaults to `print`.
  public init(
    enabled: Bool = false,
    level: Level = .info,
    logBodies: Bool = false,
    redactHeaders: [HTTPField.Name] = [.authorization],
    sink: @escaping @Sendable (String) -> Void = { print($0) }
  ) {
    self.enabled = enabled
    self.level = level
    self.logBodies = logBodies
    self.redactHeaders = redactHeaders
    self.sink = sink
  }
}

/// Logs outgoing requests and their responses.
public struct LoggingMiddleware: ClientMiddleware {
  let configuration: LoggingConfiguration
  public init(configuration: LoggingConfiguration = LoggingConfiguration(enabled: true)) {
    self.configuration = configuration
  }
  public func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    if !configuration.enabled {
      return try await next(request, body, baseURL)
    }

    let start = Date()
    var headerPreview: [String: String] = [:]
    for field in request.headerFields {
      let name = field.name
      let value = field.value
      if configuration.redactHeaders.contains(name) {
        headerPreview[name.canonicalName] = "<redacted>"
      } else {
        headerPreview[name.canonicalName] = value
      }
    }
    configuration.sink("➡️ [\(configuration.level.rawValue)] \(request.method.rawValue) \(baseURL) op=\(operationID) headers=\(headerPreview)")
    if configuration.logBodies, let body = body {
      configuration.sink("  ↳ request body: \(describeBody(body))")
    }

    do {
      let (response, responseBody) = try await next(request, body, baseURL)
      let durMs = durationMS(since: start)
      configuration.sink("✅ [\(configuration.level.rawValue)] \(Int(response.status.code)) op=\(operationID) in \(durMs)ms")
      if configuration.logBodies, let responseBody = responseBody {
        configuration.sink("  ↙︎ response body: \(describeBody(responseBody))")
      }
      return (response, responseBody)
    } catch {
      let durMs = durationMS(since: start)
      configuration.sink("❌ [\(configuration.level.rawValue)] error op=\(operationID) in \(durMs)ms: \(error)")
      throw error
    }
  }

  private func describeBody(_ body: HTTPBody) -> String {
    return "<stream>"
  }
  private func durationMS(since start: Date) -> Int {
    Int(Date().timeIntervalSince(start) * 1000.0)
  }
}

/// Adds a `Bearer` token to the `Authorization` header.
public struct TokenAuthMiddleware: ClientMiddleware {
  public let token: String
  public init(token: String) { self.token = token }
  public func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var request = request
    request.headerFields[.authorization] = "Bearer \(token)"
    return try await next(request, body, baseURL)
  }
}

/// Sets a custom `User-Agent` header for all requests.
public struct UserAgentMiddleware: ClientMiddleware {
  public let userAgent: String
  public init(userAgent: String) { self.userAgent = userAgent }
  public func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var request = request
    request.headerFields[.userAgent] = userAgent
    return try await next(request, body, baseURL)
  }
}

/// Exponential backoff policy for network retries.
public struct RetryPolicy: Sendable, Equatable {
  public var maxAttempts: Int
  public var baseDelay: TimeInterval
  public var jitter: TimeInterval
  public var retryOnStatusCodes: Set<Int>
  /// Create a retry policy.
  /// - Parameters:
  ///   - maxAttempts: Maximum attempts including the first try.
  ///   - baseDelay: Initial delay before the first retry.
  ///   - jitter: Randomization added to the delay to avoid thundering herds.
  ///   - retryOnStatusCodes: HTTP status codes that should be retried.
  public init(
    maxAttempts: Int = 3,
    baseDelay: TimeInterval = 0.25,
    jitter: TimeInterval = 0.1,
    retryOnStatusCodes: Set<Int> = Set([429, 500, 502, 503, 504])
  ) {
    self.maxAttempts = max(1, maxAttempts)
    self.baseDelay = baseDelay
    self.jitter = jitter
    self.retryOnStatusCodes = retryOnStatusCodes
  }
}

/// Retries failed requests according to a ``RetryPolicy``.
public struct RetryMiddleware: ClientMiddleware {
  public let policy: RetryPolicy
  public init(policy: RetryPolicy = RetryPolicy()) { self.policy = policy }
  public func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var attempt = 0
    var lastError: Error?
    while attempt < policy.maxAttempts {
      do {
        let (response, responseBody) = try await next(request, body, baseURL)
        let status = Int(response.status.code)
        if policy.retryOnStatusCodes.contains(status) && attempt < policy.maxAttempts - 1 {
          attempt += 1
          let delay = backoffDelay(attempt: attempt, base: policy.baseDelay, jitter: policy.jitter)
          try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
          continue
        }
        return (response, responseBody)
      } catch {
        lastError = error
        if attempt >= policy.maxAttempts - 1 { break }
        attempt += 1
        let delay = backoffDelay(attempt: attempt, base: policy.baseDelay, jitter: policy.jitter)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      }
    }
    throw lastError ?? URLError(.cannotLoadFromNetwork)
  }

  private func backoffDelay(attempt: Int, base: TimeInterval, jitter: TimeInterval) -> TimeInterval {
    let exp = pow(2.0, Double(attempt - 1))
    let raw = base * exp
    let rand = Double.random(in: -jitter...jitter)
    return max(0, raw + rand)
  }
}

/// Limits the number of concurrent in‑flight requests.
public struct ConcurrencyLimitMiddleware: ClientMiddleware {
  let gate: AsyncSemaphore
  public init(maxConcurrentRequests: Int) { self.gate = AsyncSemaphore(value: Swift.max(1, maxConcurrentRequests)) }
  public func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    await gate.acquire()
    defer { Task { await gate.release() } }
    return try await next(request, body, baseURL)
  }
}

/// A simple async semaphore used to gate concurrent requests.
public actor AsyncSemaphore {
  private let capacity: Int
  private var available: Int
  private var waiters: [CheckedContinuation<Void, Never>] = []
  public init(value: Int) {
    self.capacity = Swift.max(1, value)
    self.available = self.capacity
  }
  public func acquire() async {
    if available > 0 {
      available -= 1
      return
    }
    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
      waiters.append(cont)
    }
  }
  public func release() {
    if !waiters.isEmpty {
      let cont = waiters.removeFirst()
      cont.resume()
    } else {
      available = min(capacity, available + 1)
    }
  }
}

// MARK: - Rate limiting

/// Policy controlling behaviour on `429 Too Many Requests`.
public struct RateLimitPolicy: Sendable, Equatable {
  public var maxRetries: Int
  public var defaultDelaySeconds: TimeInterval
  public var respectRetryAfterHeader: Bool
  public init(maxRetries: Int = 1, defaultDelaySeconds: TimeInterval = 60, respectRetryAfterHeader: Bool = true) {
    self.maxRetries = max(0, maxRetries)
    self.defaultDelaySeconds = max(0, defaultDelaySeconds)
    self.respectRetryAfterHeader = respectRetryAfterHeader
  }
}

/// Retries `429` responses with an optional delay derived from `Retry-After`.
public struct RateLimitMiddleware: ClientMiddleware {
  let policy: RateLimitPolicy
  public init(policy: RateLimitPolicy = RateLimitPolicy()) { self.policy = policy }
  public func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var attempts = 0
    while true {
      let (response, responseBody) = try await next(request, body, baseURL)
      if response.status.code == 429, attempts < policy.maxRetries {
        attempts += 1
        let delay = retryAfterDelay(from: response.headerFields) ?? policy.defaultDelaySeconds
        if delay > 0 {
          try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        continue
      }
      return (response, responseBody)
    }
  }

  private func retryAfterDelay(from headers: HTTPFields) -> TimeInterval? {
    guard policy.respectRetryAfterHeader else { return nil }
    if let name = HTTPField.Name("Retry-After"), let v = headers[name] {
      if let secs = TimeInterval(v.trimmingCharacters(in: CharacterSet.whitespaces)) { return max(0, secs) }
      // Could be an HTTP-date; ignore for simplicity
    }
    return nil
  }
}
