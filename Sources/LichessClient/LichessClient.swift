import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// A typed, async Swift client for the public Lichess HTTP API.
///
/// - Features:
///   - 100% coverage of the Lichess OpenAPI 2.0 surface via generated bindings.
///   - Small, well‑named convenience wrappers with sensible defaults.
///   - Pluggable middlewares for logging, retries, rate limiting, auth, and concurrency limits.
///   - Separate base URL handling for the Tablebase endpoints.
///
/// Use ``LichessClient/init()`` for a default unauthenticated client, or
/// ``LichessClient/init(configuration:)`` to customize transport, headers, policies, and auth.
public struct LichessClient {
  // Lichess has a separate endpoint for its tablebase server
  internal let underlyingClient: any APIProtocol
  internal let underlyingTablebaseClient: any APIProtocol

  internal init(underlyingClient: any APIProtocol, underlyingTablebaseClient: any APIProtocol) {
    self.underlyingClient = underlyingClient
    self.underlyingTablebaseClient = underlyingTablebaseClient
  }

  /// Create a client that talks to the public Lichess servers using `URLSession`.
  ///
  /// This initializer is unauthenticated. For authenticated requests provide an
  /// access token using ``LichessClient/init(configuration:)`` or ``LichessClient/init(accessToken:)``.
  public init() {
    self.init(
      underlyingClient: Client(
        serverURL: URL(string: "https://lichess.org")!, transport: URLSessionTransport()),
      underlyingTablebaseClient: Client(
        serverURL: URL(string: "https://tablebase.lichess.ovh")!, transport: URLSessionTransport())
    )
  }

  /// Errors surfaced by ``LichessClient`` wrappers.
  public enum LichessClientError: Error, Sendable, CustomStringConvertible {
    case undocumentedResponse(statusCode: Int)
    case parsingError(error: Error)
    case unauthorized
    case forbidden
    case notFound
    case tooManyRequests(retryAfterSeconds: Int?)
    case httpStatus(statusCode: Int)
    public var description: String {
      switch self {
      case .undocumentedResponse(let code): return "Undocumented response (status=\(code))"
      case .parsingError(let err): return "Parsing error: \(err)"
      case .unauthorized: return "Unauthorized (401)"
      case .forbidden: return "Forbidden (403)"
      case .notFound: return "Not found (404)"
      case .tooManyRequests(let s): return "Too many requests (429), retryAfter=\(s.map(String.init) ?? "nil")"
      case .httpStatus(let code): return "HTTP error (status=\(code))"
      }
    }
  }

  // MARK: - Configuration

  /// Configuration for a ``LichessClient`` instance.
  ///
  /// You can customize the server URLs, supply a custom transport, add
  /// middlewares, turn on structured logging, and configure retry and rate
  /// limiting policies. For convenience, you can also pass a personal access
  /// token and a custom user‑agent string here.
  public struct Configuration: Sendable {
    public var serverURL: URL
    public var tablebaseServerURL: URL
    public var transport: any ClientTransport
    public var middlewares: [any ClientMiddleware]
    public var logging: LoggingConfiguration?
    public var accessToken: String?
    public var userAgent: String?
    public var maxConcurrentRequests: Int?
    public var retryPolicy: RetryPolicy?
    public var rateLimitPolicy: RateLimitPolicy?

    /// Create a configuration.
    /// - Parameters:
    ///   - serverURL: Base URL for the main Lichess API.
    ///   - tablebaseServerURL: Base URL for the Tablebase API.
    ///   - transport: HTTP client transport (defaults to `URLSession`).
    ///   - middlewares: Additional middlewares to install.
    ///   - logging: Optional request/response logging configuration.
    ///   - accessToken: Optional bearer token used for authenticated requests.
    ///   - userAgent: Optional `User-Agent` header value.
    ///   - maxConcurrentRequests: Limit of in‑flight requests when set (> 0).
    ///   - retryPolicy: Optional exponential backoff retry policy.
    ///   - rateLimitPolicy: Optional policy to respect `429` rate limits.
    public init(
      serverURL: URL = URL(string: "https://lichess.org")!,
      tablebaseServerURL: URL = URL(string: "https://tablebase.lichess.ovh")!,
      transport: any ClientTransport = URLSessionTransport(),
      middlewares: [any ClientMiddleware] = [],
      logging: LoggingConfiguration? = nil,
      accessToken: String? = nil,
      userAgent: String? = nil,
      maxConcurrentRequests: Int? = nil,
      retryPolicy: RetryPolicy? = nil,
      rateLimitPolicy: RateLimitPolicy? = nil
    ) {
      self.serverURL = serverURL
      self.tablebaseServerURL = tablebaseServerURL
      self.transport = transport
      self.middlewares = middlewares
      self.logging = logging
      self.accessToken = accessToken
      self.userAgent = userAgent
      self.maxConcurrentRequests = maxConcurrentRequests
      self.retryPolicy = retryPolicy
      self.rateLimitPolicy = rateLimitPolicy
    }
  }

  /// Create a client using a custom ``Configuration``.
  public init(configuration: Configuration) {
    var mws: [any ClientMiddleware] = configuration.middlewares
    if let log = configuration.logging, log.enabled {
      mws.append(LoggingMiddleware(configuration: log))
    }
    if let max = configuration.maxConcurrentRequests, max > 0 {
      mws.append(ConcurrencyLimitMiddleware(maxConcurrentRequests: max))
    }
    if let policy = configuration.retryPolicy { mws.append(RetryMiddleware(policy: policy)) }
    if let rl = configuration.rateLimitPolicy { mws.append(RateLimitMiddleware(policy: rl)) }
    if let ua = configuration.userAgent, !ua.isEmpty {
      mws.append(UserAgentMiddleware(userAgent: ua))
    }
    if let token = configuration.accessToken, !token.isEmpty {
      mws.append(TokenAuthMiddleware(token: token))
    }

    self.init(
      underlyingClient: Client(
        serverURL: configuration.serverURL,
        transport: configuration.transport,
        middlewares: mws
      ),
      underlyingTablebaseClient: Client(
        serverURL: configuration.tablebaseServerURL,
        transport: configuration.transport,
        middlewares: mws
      )
    )
  }

  /// Create an authenticated client using a personal access token.
  ///
  /// Equivalent to `LichessClient(configuration: .init(accessToken: token))`.
  public init(accessToken: String) {
    self.init(configuration: .init(accessToken: accessToken))
  }

}
