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

}
