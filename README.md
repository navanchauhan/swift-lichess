# Swift-Lichess

API Client for Lichess. The end goal of this package is to implement everything listed in the OpenAPI Reference (2.0.0)

## Example

```swift
import LichessClient

let client = LichessClient()

Task {
    do {
        let tournaments = try await client.broadcastIndex(nb: 10)
    } catch {
        print("Error fetching tournaments: \(error)")
    }
}
```

## OAuth / PKCE

```swift
import LichessClient

let pkce = LichessClient.generatePKCE()
let state = UUID().uuidString
let redirect = URL(string: "myapp://callback")!

// 1) Send user to this URL (open in browser / webview)
let authURL = LichessClient().buildAuthorizationURL(
  clientID: "myapp",
  redirectURI: redirect,
  scopes: ["challenge:write", "email:read"],
  state: state,
  pkce: pkce
)

// 2) Handle redirect back to your app and extract the `code`
// let code = ...

// 3) Exchange code for token
let token = try await LichessClient().exchangeCodeForToken(
  clientID: "myapp",
  code: code,
  redirectURI: redirect,
  codeVerifier: pkce.codeVerifier
)

// 4) Create an authenticated client
let authed = LichessClient(accessToken: token.accessToken)
```

## Users & Profiles

```swift
import LichessClient

let client = LichessClient()
let user = try await client.getUser(username: "thibault")
print(user.username, user.title ?? "-")

// If authenticated
let me = try await client.getMyProfile()
let email = try await client.getMyEmail()
```

## Configuration, Transport, and Auth

```swift
import LichessClient

// Provide an access token and custom headers via middlewares
let client = LichessClient(configuration: .init(
  accessToken: "<your PAT>",
  userAgent: "swift-lichess/1.0 (+https://github.com/navanchauhan/swift-lichess)",
  maxConcurrentRequests: 4,
  retryPolicy: .init(maxAttempts: 3),
  // You can also pass a custom transport and additional middlewares
  // transport: MyCustomTransport(),
  // middlewares: [MyMiddleware()]
))
```

## Streams (NDJSON)

```swift
import LichessClient

let client = LichessClient()

// Example: consume official broadcasts stream
let stream = try await client.broadcastIndex(nb: 5)
for try await t in stream {
  print(t.tour.name)
}

// Or decode any NDJSON HTTPBody into a typed stream
struct Item: Decodable { let a: Int }
let body: HTTPBody = HTTPBody("{\"a\":1}\n{\"a\":2}\n")
for try await item in Streaming.ndjsonStream(from: body, as: Item.self) {
  print(item)
}
```

## Players (Leaderboards)

```swift
let client = LichessClient()

// All Top-10 lists per perf key
let top = try await client.getAllTop10()
print("Top-10 Bullet count:", top["bullet"]?.count ?? 0)

// One leaderboard (up to 200 entries)
let blitzTop = try await client.getLeaderboard(perfType: "blitz", nb: 50)
print(blitzTop.first?.username ?? "-")
```

## Puzzles

```swift
let client = LichessClient()

// Daily puzzle
let daily = try await client.getDailyPuzzle()
print(daily.puzzle.id, daily.puzzle.themes)

// Puzzle by ID
let p = try await client.getPuzzle(id: daily.puzzle.id)
print(p.game.perf.name, p.puzzle.rating)

// Next puzzle (optionally filter by theme)
let next = try await client.getNextPuzzle(angle: "mateIn2")
print(next.puzzle.id)
```

## Tablebase (Standard, Atomic, Antichess)

```swift
let client = LichessClient()
let standard = try await client.getStandardTablebase(fen: "4k3/6KP/8/8/8/8/7p/8 w - - 0 1")
print(standard.dtm ?? -1, standard.moves?.count ?? 0)

// Variants
let atomic = try await client.getAtomicTablebase(fen: "8/8/8/8/8/8/8/8 w - - 0 1")
let antichess = try await client.getAntichessTablebase(fen: "8/8/8/8/8/8/8/8 w - - 0 1")
```

## Game/TV Streams

```swift
let client = LichessClient()

// Stream one ongoing game
let gameBody = try await client.streamGame(gameId: "abcdefgh")
for try await event in Streaming.ndjsonStream(from: gameBody, as: Components.Schemas.GameStateEvent.self) {
  print(event.moves)
}

// Stream current TV game
let tvBody = try await client.streamTVFeed()
for try await evt in Streaming.ndjsonStream(from: tvBody, as: Components.Schemas.GameFullEvent.self) {
  print(evt.id)
}

// TV channels and per-channel games
let tv = try await client.getTVChannels()
for (channel, game) in tv.entries { print(channel, game.user.name, game.rating) }

// Stream a specific channel feed (NDJSON)
let chBody = try await client.streamTVChannelFeed(channel: "rapid")
struct TVMin: Decodable { let t: String? }
for try await item in Streaming.ndjsonStream(from: chBody, as: TVMin.self) { print(item.t ?? "-"); break }

// Fetch best ongoing Blitz games (PGN or NDJSON via `format`)
_ = try await client.getTVChannelGames(channel: "blitz", format: .pgn, nb: 10)
```

## Opening Explorer (Masters, Lichess, Player DB)

```swift
let client = LichessClient()

// Masters DB
let masters = try await client.getOpeningExplorerMasters(
  fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
  moves: 10,
  topGames: 3
)
print(masters.moves.map(\.san))

// Lichess DB with filters
let lichess = try await client.getOpeningExplorerLichess(
  variant: "standard",
  fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
  speeds: ["blitz", "rapid"],
  ratings: [2200, 2500],
  recentGames: 5,
  history: true
)
print(lichess.topGames.count)

// Player DB stream (NDJSON)
let playerBody = try await client.streamOpeningExplorerPlayer(
  player: "revoof",
  color: "white",
  play: ["d2d4", "d7d5"],
  recentGames: 1
)
for try await item in Streaming.ndjsonStream(from: playerBody, as: Components.Schemas.OpeningExplorerPlayer.self) {
  print(item)
}
```

## Tournaments & Swiss

```swift
let client = LichessClient()

// Arena export (PGN or NDJSON)
let pgnBody = try await client.exportTournamentGames(id: "abcd1234", format: .pgn)
let jsonBody = try await client.exportTournamentGames(id: "abcd1234", format: .ndjson)

// Arena results (NDJSON)
let results = try await client.streamTournamentResults(id: "abcd1234", nb: 100)
for try await row in Streaming.ndjsonStream(from: results, as: Components.Schemas.OpenAPIRuntime.OpenAPIValueContainer.self) {
  print(row)
}

// Swiss export & results
_ = try await client.exportSwissGames(id: "j8rtJ5GL", format: .pgn)
let swissResults = try await client.streamSwissResults(id: "j8rtJ5GL")
```

## Studies (PGN export, list, import)

```swift
let client = LichessClient(accessToken: "<study:read study:write>")

// One chapter PGN
let chapterPGN = try await client.getStudyChapterPGN(studyId: "lXnKRxIP", chapterId: "JT3RkEwv")

// Whole study PGN
let studyPGN = try await client.getStudyPGN(studyId: "lXnKRxIP")

// List studies metadata (NDJSON)
let metaBody = try await client.listUserStudiesMetadata(username: "thibault")

// Import multiple PGN games as chapters
let raw = "[Event \"A\"]\n\n1. e4 e5 *\n\n\n[Event \"B\"]\n\n1. d4 d5 *"
let sanitized = PGNUtilities.sanitizeForImport(raw)
let importResult = try await client.importPGNIntoStudy(studyId: "lXnKRxIP", pgn: sanitized)
print(importResult.chapters.map { $0?.name ?? "-" })
```

## Cloud Evaluation

```swift
let client = LichessClient()
let fen = "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3"
if let eval = try await client.getCloudEval(fen: fen, multiPv: 3) {
  print("depth=\(eval.depth) knodes=\(eval.knodes)")
  print(eval.pvs.first?.moves.joined(separator: " ") ?? "-")
}
```

## Diagnostics & Resilience

```swift
// Enable logging and rate limit handling
let client = LichessClient(configuration: .init(
  userAgent: "swift-lichess/1.0",
  logging: .init(enabled: true, level: .info, logBodies: false),
  retryPolicy: .init(maxAttempts: 3),
  rateLimitPolicy: .init(maxRetries: 1, defaultDelaySeconds: 60)
))
```
