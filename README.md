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

### Autocomplete

```swift
let client = LichessClient()

// Get usernames or user objects matching a prefix
let ac = try await client.autocompletePlayers(term: "magn", object: true)
switch ac {
case .usernames(let names):
  print(names.prefix(5))
case .users(let users):
  print(users.prefix(5).map(\.name))
}
```

## Account

```swift
import LichessClient

let client = LichessClient(accessToken: "<token>")

// Preferences & language
let prefs = try await client.getMyPreferences()
print(prefs.language ?? "-", prefs.dark ?? false)

// Kid mode
let kid = try await client.getKidMode()
_ = try await client.setKidMode(kid) // no-op

// Ongoing games
let mine = try await client.getMyOngoingGames(nb: 5)
print(mine.first?.gameId ?? "-")
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

## Broadcasts

```swift
import LichessClient

let client = LichessClient()

// Top broadcasts (active, upcoming, and past pages)
let top = try await client.getTopBroadcasts(page: 1)
print("Active: \(top.active.count), Upcoming: \(top.upcoming.count)")

// Round details
let details = try await client.broadcastRound(broadcastRoundId: "<round-id>")
print(details.tour.name, details.round.name, details.games.count)

// All rounds PGN for a tournament
let pgnAll = try await client.getBroadcastAllRoundsPGN(tournamentId: "<tour-id>")
for try await _ in pgnAll { break } // consume stream
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

// Your puzzle activity (NDJSON stream)
let act = try await client.getPuzzleActivity(max: 10)
for try await _ in act { break }

// Puzzle replay summary (30 days, theme "fork")
let replay = try await client.getPuzzleReplay(days: 30, theme: "fork")
print(replay?.remaining.count ?? 0)
```

## Game Export / Import

```swift
import LichessClient

let client = LichessClient()

// Export one game as PGN
let pgn = try await client.exportGame(id: "abcdefgh", format: .pgn)
for try await _ in pgn { break }

// Export recent games of a user (PGN or NDJSON)
let userGames = try await client.exportUserGames(username: "thibault", format: .pgn, max: 10)
for try await _ in userGames { /* consume */ }

// Export specific games by IDs (NDJSON)
let idsBody = try await client.exportGamesByIds(ids: ["abcdefgh", "ijklmnop"], format: .ndjson, moves: true)
for try await _ in idsBody { break }

// Import a PGN as a new game
let res = try await client.importGame(pgn: "[Event \"Casual\"]\n1. e4 e5 *")
print(res.id, res.url)
```

## Crosstable

```swift
let client = LichessClient()
let ct = try await client.getCrosstable(user1: "drnykterstein", user2: "rebeccaharris")
print(ct.nbGames, ct.scores)
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

// Incoming events stream (NDJSON)
let evBody = try await client.streamIncomingEvents()
struct Incoming: Decodable { let type: String }
for try await e in Streaming.ndjsonStream(from: evBody, as: Incoming.self) {
  print(e.type); break
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
// Fetch PGN of a Masters game by id
let mastersPGN = try await client.getOpeningExplorerMastersGamePGN(gameId: "<game-id>")
for try await _ in mastersPGN { break }
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

### Arena

```swift
let client = LichessClient()

// Schedule
let sched = try await client.getCurrentTournaments()
print("upcoming:", sched.created.count)

// Details
let t = try await client.getArenaTournament(id: "abcd1234")
print(t.name, t.clock.timeMinutes, t.clock.incrementSeconds)
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
// Delete a chapter (requires permission)
_ = try? await client.deleteStudyChapter(studyId: "lXnKRxIP", chapterId: "JT3RkEwv")
// HEAD for last-modified of full PGN
let lastMod = try await client.getStudyPGNLastModified(studyId: "lXnKRxIP")
print(lastMod?.description ?? "-")
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
## Simuls

```swift
let client = LichessClient()
let simuls = try await client.getSimuls()
print(simuls.created.count, simuls.started.count)
```
## FIDE

```swift
let client = LichessClient()
let fide = try await client.getFIDEPlayer(id: 750419)
print(fide.name, fide.standard ?? -1)

let matches = try await client.searchFIDEPlayers(query: "Carlsen")
print(matches.prefix(3).map(\.name))
```
## Streamers

```swift
let client = LichessClient()
let live = try await client.getLiveStreamers()
print(live.prefix(3).map { ($0.id, $0.service ?? "-") })
```

## Teams

```swift
let client = LichessClient()

// Team details
let team = try await client.getTeam(id: "lichess")
print(team.name, team.nbMembers ?? 0)

// Popular and search
let popular = try await client.getPopularTeams(page: 1)
let search = try await client.searchTeams(text: "chess", page: 1)
print(popular.results.count, search.results.count)

// Teams of a user
let userTeams = try await client.getTeams(of: "thibault")
print(userTeams.map(\.name))

// Streams (NDJSON)
let arenaBody = try await client.streamTeamArena(teamId: "lichess", max: 1)
struct ArenaItem: Decodable {}
for try await _ in Streaming.ndjsonStream(from: arenaBody, as: ArenaItem.self) { break }
```

## Bulk Pairing

```swift
// Requires an authenticated client with `challenge:write` scope
let client = LichessClient(accessToken: "<token>")

// List your scheduled bulks
let bulks = try await client.listBulkPairings()
print(bulks.count)

// Create a real-time bulk pairing for two games (example tokens)
/*
let created = try await client.createBulkPairing(
  pairs: [(whiteToken: "tokenW1", blackToken: "tokenB1"), (whiteToken: "tokenW2", blackToken: "tokenB2")],
  clockLimit: 600, clockIncrement: 2,
  options: .init(variant: "standard", rated: true, message: "Good luck! {game}")
)
*/

// Export games of a bulk as PGN
if let first = bulks.first {
  let body = try await client.exportBulkPairingGames(id: first.id, format: .pgn, moves: true)
  for try await _ in body { /* consume */ }
}
```

### Admin (Challenge Tokens)

```swift
// Admin-only: create or reuse challenge:write tokens for users
let admin = LichessClient(accessToken: "<admin_token>")
let map = try await admin.adminCreateChallengeTokens(usernames: ["alice","bob"], description: "Bulk pairing")
print(map["alice"] ?? "-")
```

## External Engine

```swift
// Requires auth; register/list your external engines
let client = LichessClient(accessToken: "<token>")

let engines = try await client.listExternalEngines()
if let e = engines.first {
  let common = LichessClient.ExternalEngineWorkCommon(
    sessionId: UUID().uuidString,
    threads: min(1, e.maxThreads),
    hash: min(16, e.maxHash),
    multiPv: 1,
    variant: "chess",
    initialFEN: "startpos",
    moves: []
  )
  let ndjson = try await client.analyseWithExternalEngine(
    id: e.id, clientSecret: e.clientSecret, work: .depth(ply: 5, common: common)
  )
  // consume ndjson as needed
}
```

## Board API

```swift
// Board API typically requires an authenticated client with scopes
let client = LichessClient(accessToken: "<token>")

// Create a realtime seek (5+0), random color
let result = try await client.createBoardSeek(
  kind: .realtime(timeMinutes: 5, incrementSeconds: 0),
  options: .init(rated: true, variant: "standard")
)
switch result {
case .realtime(let body):
  // stream NDJSON if provided
  for try await _ in body { break }
case .correspondence(let id):
  print("Correspondence seek id:", id)
}

// Stream one game
let nd = try await client.streamBoardGame(gameId: "<your-game-id>")
for try await _ in Streaming.ndjsonStream(from: nd, as: Components.Schemas.OpenAPIRuntime.OpenAPIValueContainer.self) { break }
```

## Bot API

```swift
// Most Bot endpoints require a Bot account + token (bot:play scope)
let client = LichessClient(accessToken: "<token>")

// Online bots stream
let bots = try await client.streamOnlineBots()
for try await _ in bots { break }

// Stream a bot game
let gameBody = try await client.streamBotGame(gameId: "<game-id>")
for try await _ in Streaming.ndjsonStream(from: gameBody, as: Components.Schemas.OpenAPIRuntime.OpenAPIValueContainer.self) { break }
```

## Challenges

```swift
let client = LichessClient(accessToken: "<token>")

// List challenges
let challenges = try await client.listChallenges()
print(challenges.incoming.count, challenges.outgoing.count)

// Create a realtime challenge (3+2) to a user
let created = try await client.createChallenge(
  username: "thibault",
  time: .realtime(limitSeconds: 180, incrementSeconds: 2),
  options: .init(rated: true, color: "random", variant: "standard")
)
print(created.id)
```
