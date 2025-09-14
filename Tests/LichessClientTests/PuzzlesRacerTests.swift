import XCTest
@testable import LichessClient
import OpenAPIRuntime
import HTTPTypes

final class PuzzlesRacerTests: XCTestCase {
  struct Transport: ClientTransport {
    let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) { try await handler(request, body, baseURL, operationID) }
  }

  func testPuzzleActivityNDJSONAccept() async throws {
    var seenAccept: String?
    let transport = Transport { req, _, _, op in
      XCTAssertEqual(op, "apiPuzzleActivity")
      seenAccept = req.headerFields[.accept]
      return (HTTPResponse(status: .ok), HTTPBody("{}\n"))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    _ = try await client.getPuzzleActivity(max: 10)
    XCTAssertTrue(seenAccept?.contains("application/x-ndjson") ?? false)
  }

  func testPuzzleReplayMapsFields() async throws {
    let json = """
    {"replay":{"days":30,"theme":"fork","nb":12,"remaining":["abc","def"]},"angle":{"key":"tactics","name":"Tactics","desc":"desc"}}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiPuzzleReplay")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let rep = try await client.getPuzzleReplay(days: 30, theme: "fork")
    XCTAssertEqual(rep?.theme, "fork")
    XCTAssertEqual(rep?.remaining.count, 2)
    XCTAssertEqual(rep?.angleKey, "tactics")
  }

  func testPuzzleDashboardMapsGlobal() async throws {
    let json = """
    {"days":30,"global":{"firstWins":1,"nb":2,"performance":3,"puzzleRatingAvg":4,"replayWins":5},"themes":{"fork":{"results":{"firstWins":6,"nb":7,"performance":8,"puzzleRatingAvg":9,"replayWins":10},"theme":"fork"}}}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiPuzzleDashboard")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let dash = try await client.getPuzzleDashboard(days: 30)
    XCTAssertEqual(dash.days, 30)
    XCTAssertEqual(dash.global.nb, 2)
    XCTAssertNotNil(dash.themes["fork"])
  }

  func testStormDashboardMaps() async throws {
    let json = """
    {"days":[{"_id":"d1","combo":1,"errors":0,"highest":2,"moves":3,"runs":4,"score":5,"time":60}],"high":{"allTime":42,"day":10,"month":20,"week":15}}
    """
    let transport = Transport { _, _, _, op in
      XCTAssertEqual(op, "apiStormDashboard")
      return (HTTPResponse(status: .ok), HTTPBody(json))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let s = try await client.getStormDashboard(username: "user")
    XCTAssertEqual(s.days.first?.score, 5)
    XCTAssertEqual(s.high.allTime, 42)
  }

  func testRacerCreateAndGet() async throws {
    var step = 0
    let transport = Transport { req, _, _, op in
      if op == "racerPost" { step = 1; return (HTTPResponse(status: .ok), HTTPBody("{\"id\":\"rid\",\"url\":\"https://lichess.org/racer/rid\"}")) }
      if op == "racerGet" { XCTAssertEqual(step, 1); return (HTTPResponse(status: .ok), HTTPBody("{\"id\":\"rid\",\"owner\":\"me\",\"players\":[{\"name\":\"p\",\"score\":3}],\"puzzles\":[],\"finishesAt\":1,\"startsAt\":0}")) }
      return (HTTPResponse(status: .notFound), HTTPBody("{\"error\":\"nf\"}"))
    }
    let client = LichessClient(configuration: .init(transport: transport))
    let created = try await client.createRacer()
    XCTAssertEqual(created.id, "rid")
    let res = try await client.getRacer(id: created.id)
    XCTAssertEqual(res?.owner, "me")
  }
}

