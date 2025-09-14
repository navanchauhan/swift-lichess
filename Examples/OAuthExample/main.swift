import Foundation
import LichessClient

struct OAuthExample {
  static func main() async {
    let client = LichessClient()
    let pkce = LichessClient.generatePKCE()
    let state = UUID().uuidString
    let redirect = URL(string: "myapp://callback")!
    let url = client.buildAuthorizationURL(
      clientID: "myapp",
      redirectURI: redirect,
      scopes: ["challenge:write", "email:read"],
      state: state,
      pkce: pkce
    )
    print(url.absoluteString)
  }
}

