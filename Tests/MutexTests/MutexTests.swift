import XCTest
@testable import Mutex

class MutexTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(Mutex().text, "Hello, World!")
    }


    static var allTests : [(String, (MutexTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
