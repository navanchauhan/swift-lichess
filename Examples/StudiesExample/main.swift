import Foundation
import LichessClient

struct StudiesExample {
  static func main() async {
    let client = LichessClient()
    do {
      // Check last-modified of full study PGN
      if let lm = try await client.getStudyPGNLastModified(studyId: "lXnKRxIP") {
        print("Last-Modified:", lm)
      }
      // Delete a chapter (requires permissions on the study)
      _ = try? await client.deleteStudyChapter(studyId: "<study>", chapterId: "<chapter>")
    } catch {
      print("StudiesExample error: \(error)")
    }
  }
}

