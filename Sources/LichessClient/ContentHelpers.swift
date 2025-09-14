import Foundation

public enum PGNUtilities {
  /// Split a multi-game PGN string into individual game PGNs.
  /// The Studies importer accepts multiple games separated by 2+ blank lines.
  public static func splitGames(_ pgn: String) -> [String] {
    let normalized = normalizeNewlines(pgn).trimmingCharacters(in: .whitespacesAndNewlines)
    var parts: [String] = []
    var buffer: [String] = []
    var blankRun = 0
    for line in normalized.components(separatedBy: "\n") {
      if line.trimmingCharacters(in: .whitespaces).isEmpty {
        blankRun += 1
      } else {
        if blankRun >= 2 && !buffer.isEmpty {
          parts.append(buffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines))
          buffer.removeAll(keepingCapacity: true)
        }
        blankRun = 0
      }
      buffer.append(line)
    }
    if !buffer.isEmpty {
      parts.append(buffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines))
    }
    return parts.filter { !$0.isEmpty }
  }

  /// Join multiple single-game PGNs, inserting 2 blank lines between games.
  public static func joinGames(_ games: [String]) -> String {
    let trimmed = games.map { normalizeNewlines($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    return trimmed.joined(separator: "\n\n\n")
  }

  /// Parse the tag pair section at the top of a PGN into a dictionary.
  public static func parseTags(from pgn: String) -> [String: String] {
    var tags: [String: String] = [:]
    let lines = normalizeNewlines(pgn).components(separatedBy: "\n")
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard trimmed.hasPrefix("[") && trimmed.hasSuffix("]") else { break }
      let inner = String(trimmed.dropFirst().dropLast())
      guard let spaceIdx = inner.firstIndex(of: " ") else { continue }
      let key = String(inner[..<spaceIdx])
      let rawValue = inner[inner.index(after: spaceIdx)...].trimmingCharacters(in: .whitespaces)
      let value = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "\"").union(.whitespaces))
      if !key.isEmpty { tags[key] = value }
    }
    return tags
  }

  /// Remove comments {...}, variations (...) and NAGs ($123) from movetext.
  public static func stripCommentsVariationsAndNAGs(_ pgn: String) -> String {
    let normalized = normalizeNewlines(pgn)
    let noComments = replacing(pattern: #"\{[^}]*\}"#, in: normalized, with: " ")
    // This removes simple (non-nested) parenthetical variations which is sufficient for many PGNs
    let noVars = replacing(pattern: #"\([^()]*\)"#, in: noComments, with: " ")
    let noNAGs = replacing(pattern: #"\$\d+"#, in: noVars, with: " ")
    return condenseWhitespace(noNAGs).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Sanitize PGN before import: normalize newlines and ensure proper game separators.
  public static func sanitizeForImport(_ pgn: String) -> String {
    let games = splitGames(pgn)
    return joinGames(games)
  }

  // MARK: - Internals
  private static func normalizeNewlines(_ s: String) -> String {
    s.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
  }

  private static func replacing(pattern: String, in text: String, with replacement: String) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
      return text
    }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
  }

  private static func condenseWhitespace(_ s: String) -> String {
    let components = s.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    return components.joined(separator: " ")
  }
}

