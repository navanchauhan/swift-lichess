import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class StudiesExtraTests: XCTestCase {
  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
      try await handler(request, body, baseURL, operationID)
    }
  }

  func testDeleteStudyChapter204() async throws {
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiStudyStudyIdChapterIdDelete")
      return (HTTPResponse(status: .noContent), nil)
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let ok = try await client.deleteStudyChapter(studyId: "S", chapterId: "C")
    XCTAssertTrue(ok)
  }

  func testStudyLastModifiedParsesDate() async throws {
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "studyAllChaptersHead")
      var resp = HTTPResponse(status: .noContent)
      resp.headerFields[HTTPField.Name("Last-Modified")!] = "Wed, 21 Oct 2015 07:28:00 GMT"
      return (resp, nil)
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let date = try await client.getStudyPGNLastModified(studyId: "S")
    XCTAssertNotNil(date)
  }
}

