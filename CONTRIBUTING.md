Contributing

Thanks for helping improve swift-lichess! This guide covers how to add a new public wrapper for a generated operation and how to verify API coverage.

Prerequisites
- Swift 5.9+
- Optional: `ripgrep` for quick coverage checks

Project layout
- Generated types and client live under `Sources/LichessClient/GeneratedSources/`.
- Public wrappers live in `Sources/LichessClient/LichessClient+*.swift`, grouped by API area.
- `LichessClient` provides configuration, middlewares, and error mapping.

Add a new wrapper
- Choose the appropriate `LichessClient+Area.swift` file, or create a new one following the existing naming pattern.
- Locate the generated operation in `GeneratedSources/Client.swift` or `GeneratedSources/Types.swift` (search for `Operations.<name>`).
- Call the operation via `underlyingClient.<operation>(...)` (or `underlyingTablebaseClient` for tablebase endpoints).
- Map responses to friendly Swift APIs:
  - Switch on the generated enum (e.g., `.ok`, `.noContent`, `.badRequest`, `.undocumented`).
  - Throw `LichessClientError` for non-success cases to keep behavior consistent.
  - Return value types should be convenient (e.g., simple structs, `HTTPBody` for NDJSON streams).
- Streaming and formats:
  - NDJSON endpoints: return `HTTPBody` and suggest decoding via `Streaming.ndjsonStream`.
  - Endpoints supporting PGN/JSON: set `Accept` like existing examples (see `getUserCurrentGame`).
- Naming style:
  - `getX`, `listX`, `createX`, `updateX`, `deleteX`, `streamX` as appropriate.
  - Add `@discardableResult` when the return value is typically unused (e.g., toggles, deletions).
- Tablebase:
  - Use `underlyingTablebaseClient` for `tablebaseStandard/Atomic/Antichess` operations.

Test (optional but encouraged)
- Add focused unit tests under `Tests/LichessClientTests/`.
- Use the `ClosureTransport` in tests to assert the operation id, method, headers, and body.

Verify coverage
- Unique generated operations:
  - `rg -N --no-filename -o '^\s*internal func\s+([A-Za-z0-9_]+)\(' Sources/LichessClient/GeneratedSources/Client.swift | sort -u | wc -l`
- Unique operations referenced by wrappers:
  - `rg -N --no-filename -o 'underlying(Client|TablebaseClient)\.([A-Za-z0-9_]+)\(' Sources/LichessClient/LichessClient+*.swift | sed -E 's/.*\.([A-Za-z0-9_]+)\(.*/\1/' | sort -u | wc -l`
- Per-area unique operation counts:
  - `python3 - << 'PY'\nimport os,re,glob\npat=re.compile(r'underlying(?:Client|TablebaseClient)\\.([A-Za-z0-9_]+)\\(')\nfor f in sorted(glob.glob('Sources/LichessClient/LichessClient+*.swift')):\n  ops=set()\n  for line in open(f):\n    ops.update(m.group(1) for m in pat.finditer(line))\n  print(os.path.basename(f), len(ops))\nPY`

Submitting changes
- Follow existing file structure and formatting.
- Keep changes minimal and focused on the operation you’re exposing.
- Update `README.md` coverage numbers if totals change.
