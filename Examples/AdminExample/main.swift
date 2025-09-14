import Foundation
import LichessClient

@main
struct AdminExample {
  static func main() async {
    // Requires an authenticated client with admin privileges.
    let client = LichessClient(accessToken: "<admin_token>")
    do {
      let tokens = try await client.adminCreateChallengeTokens(usernames: ["alice","bob"], description: "Bulk pairing tokens")
      print(tokens)
    } catch {
      print("AdminExample error: \(error)")
    }
  }
}

