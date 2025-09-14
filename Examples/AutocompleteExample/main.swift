import Foundation
import LichessClient

struct AutocompleteExample {
  static func main() async {
    let client = LichessClient()
    do {
      let result = try await client.autocompletePlayers(term: "magn", object: true)
      switch result {
      case .usernames(let names):
        print(names.prefix(3))
      case .users(let users):
        print(users.prefix(3).map { "\($0.name)\($0.online == true ? " (online)" : "")" })
      }
    } catch {
      print("Autocomplete error: \(error)")
    }
  }
}

