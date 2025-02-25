import XCTest
import OSLog
import Foundation
@testable import SupaTODOModel

let logger: Logger = Logger(subsystem: "SupaTODOModel", category: "Tests")

@available(macOS 13, *)
final class SupaTODOModelTests: XCTestCase {
    func testSupaTODOModel() throws {
        logger.log("running testSupaTODOModel")
        XCTAssertEqual(1 + 2, 3, "basic test")
        
        // load the TestData.json file from the Resources folder and decode it into a struct
        let resourceURL: URL = try XCTUnwrap(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        XCTAssertEqual("SupaTODOModel", testData.testModuleName)
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
