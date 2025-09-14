import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public struct LichessClient {
  // Lichess has a separate endpoint for its tablebase server
  internal let underlyingClient: any APIProtocol
  internal let underlyingTablebaseClient: any APIProtocol

  internal init(underlyingClient: any APIProtocol, underlyingTablebaseClient: any APIProtocol) {
    self.underlyingClient = underlyingClient
    self.underlyingTablebaseClient = underlyingTablebaseClient
  }

  public init() {
    self.init(
      underlyingClient: Client(
        serverURL: URL(string: "https://lichess.org")!, transport: URLSessionTransport()),
      underlyingTablebaseClient: Client(
        serverURL: URL(string: "https://tablebase.lichess.ovh")!, transport: URLSessionTransport())
    )
  }

  enum LichessClientError: Error {
    case undocumentedResponse(statusCode: Int)
    case parsingError(error: Error)
  }

  // MARK: - Configuration

  public struct Configuration: Sendable {
    public var serverURL: URL
    public var tablebaseServerURL: URL
    public var transport: any ClientTransport
    public var middlewares: [any ClientMiddleware]
    public var accessToken: String?
    public var userAgent: String?
    public var maxConcurrentRequests: Int?
    public var retryPolicy: RetryPolicy?

    public init(
      serverURL: URL = URL(string: "https://lichess.org")!,
      tablebaseServerURL: URL = URL(string: "https://tablebase.lichess.ovh")!,
      transport: any ClientTransport = URLSessionTransport(),
      middlewares: [any ClientMiddleware] = [],
      accessToken: String? = nil,
      userAgent: String? = nil,
      maxConcurrentRequests: Int? = nil,
      retryPolicy: RetryPolicy? = nil
    ) {
      self.serverURL = serverURL
      self.tablebaseServerURL = tablebaseServerURL
      self.transport = transport
      self.middlewares = middlewares
      self.accessToken = accessToken
      self.userAgent = userAgent
      self.maxConcurrentRequests = maxConcurrentRequests
      self.retryPolicy = retryPolicy
    }
  }

  public init(configuration: Configuration) {
    var mws: [any ClientMiddleware] = configuration.middlewares
    if let max = configuration.maxConcurrentRequests, max > 0 {
      mws.append(ConcurrencyLimitMiddleware(maxConcurrentRequests: max))
    }
    if let policy = configuration.retryPolicy {
      mws.append(RetryMiddleware(policy: policy))
    }
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

  public init(accessToken: String) {
    self.init(configuration: .init(accessToken: accessToken))
  }

}
