# Endpoints Overview

Swift‑Lichess groups convenience wrappers by API area. Each method delegates to
the generated OpenAPI client and returns strongly typed models or `HTTPBody`
streams.

## Users and Accounts

- Autocomplete players and fetch public profiles
- Bulk users, status, and current game
- Account preferences, email, ongoing games, and kid mode

## Puzzles

- Daily puzzle, puzzle by ID, next puzzle
- Activity streams and replay summaries

## Broadcasts, TV, and Games

- Top broadcasts and round details
- Export/import games as PGN or NDJSON streams
- TV channels, current game, and channel feeds

## Tournaments and Swiss

- Arena tournaments: list, details, join, update
- Swiss: details, schedule, pairing helpers

## Board and Bot APIs

- Create seeks and challenges, stream/play games
- Bot account management and game streams

## Opening Explorer and Tablebases

- Masters/Lichess/player databases
- Standard, Atomic, and Antichess tablebases

## Teams, Streamers, Players, and More

- Team search, membership, events
- Streamers, leaderboards, FIDE, timelines, events

Refer to the symbol documentation in each extension file (for example,
``LichessClient`` in the `LichessClient+Users.swift` family) for exact method
signatures and return types.

