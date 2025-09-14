import Foundation
import OpenAPIRuntime
import HTTPTypes

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

public struct RetryPolicy: Sendable, Equatable {
  public var maxAttempts: Int
  public var baseDelay: TimeInterval
  public var jitter: TimeInterval
  public var retryOnStatusCodes: Set<Int>
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
