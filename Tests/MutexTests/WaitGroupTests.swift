/*
    WaitGroupTests.swift

    Copyright (c) 2017 Stephen Whittle  All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

import XCTest

import ISFLibrary
import Dispatch

@testable import Mutex

class WaitGroupTests: XCTestCase {
    func _testWaitGroup(count: Int, individualAdds: Bool) throws {
        let mutex = try Mutex()
        var total = 0
        let expectedTotal = makeTotal(count)

        let waitGroup = try WaitGroup()

        let closure = { (count: Int) -> Void in
            DispatchQueue(label: "com.waitgroup.test", qos: .background).async {
                wrapper(do: {
                            try mutex.lock {
                                total += count
                            }

                            try waitGroup.done()
                        },
                        catch: { failure in
                            mutexLogger(failure)
                        })
            }
        }

        if (!individualAdds) {
            try waitGroup.add(count)
        }

        for i in 0 ..< count {
            if (individualAdds) {
                try waitGroup.add(1)
            }

            closure(i)
        }

        try waitGroup.wait()

        XCTAssertEqual(expectedTotal, total, "expected total is incorrect. expectedTotal: \(expectedTotal), total: \(total)")
    }

    func testWaitGroupZero() {
        var completed = false

        do {
            try _testWaitGroup(count: 0, individualAdds: false)

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testWaitGroupTen() {
        var completed = false

        do {
            try _testWaitGroup(count: 10, individualAdds: false)

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testWaitGroupHundred() {
        var completed = false

        do {
            try _testWaitGroup(count: 100, individualAdds: false)

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testWaitGroupIndividualAdds() {
        var completed = false

        do {
            try _testWaitGroup(count: 100, individualAdds: true)

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testWaitGroupNegative() {
        var completed = false

        do {
            try _testWaitGroup(count: -100, individualAdds: false)

            completed = true
        } catch MutexError.NegativeWaitGroup {
            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

#if !os(OSX)
    static let allTests = [
        ("testWaitGroupZero", testWaitGroupZero),
        ("testWaitGroupTen", testWaitGroupTen),
        ("testWaitGroupHundred", testWaitGroupHundred),
        ("testWaitGroupIndividualAdds", testWaitGroupIndividualAdds),
        ("testWaitGroupNegative", testWaitGroupNegative)
    ]
#endif
}
