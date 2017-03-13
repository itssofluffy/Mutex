/*
    ConditionTests.swift

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

import Foundation
import ISFLibrary
import Dispatch

@testable import Mutex

class ConditionTests: XCTestCase {
    func _testConditionBroadcast(_ count: Int) throws {
        var done = false
        let mutex = try Mutex()
        var total = 0
        let expectedTotal = makeTotal(count)
        let condition = try Condition(Mutex())
        let waitGroup = try WaitGroup()

        let closure = { (count: Int) -> Void in
            DispatchQueue(label: "com.condition.test", qos: .background).async {
                wrapper(do: {
                            try condition.mutex.lock {
                                while (!done) {
                                    try condition.wait()
                                }
                            }

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

        try waitGroup.add(count)

        for i in 0 ..< count {
            closure(i)
        }

        try condition.mutex.lock {
            done = true

            try condition.broadcast()
        }

        try waitGroup.wait()

        XCTAssert(expectedTotal == total, "The expected total is incorrect. expectedTotal: \(expectedTotal), total: \(total)")
    }

    func testConditionSignal() {
        var completed = false

        do {
            var value = "A"
            let condition = try Condition(Mutex())

            DispatchQueue(label: "com.condition.test", qos: .background).async {
                wrapper(do: {
                            try condition.mutex.lock {
                                value += "B"

                                try condition.signal()
                            }
                        },
                        catch: { failure in
                            mutexLogger(failure)
                        })
            }

            try condition.mutex.lock {
                while (value != "AB") {
                    try condition.wait()
                }
            }

            value += "C"

            XCTAssert(value == "ABC", "Expecting the value to be 'ABC'. Got \(value)")

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testConditionTimeout() {
        var completed = false

        do {
            let condition = try Condition(Mutex())
            let start = now()

            let waitTime = TimeInterval(milliseconds: 100)

            try condition.wait(waitTime)

            XCTAssert(now() - start > waitTime, "wait() returned too quickly")

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testConditionBroadcastZero() {
        var completed = false

        do {
            for _ in 0 ..< 50 {
                try _testConditionBroadcast(0)
            }

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testConditionBroadcastTen() {
        var completed = false

        do {
            for _ in 0 ..< 50 {
                try _testConditionBroadcast(10)
            }

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testConditionBroadcastHundred() {
        var completed = false

        do {
            for _ in 0 ..< 50 {
                try _testConditionBroadcast(100)
            }

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

#if !os(OSX)
    static let allTests = [
        ("testConditionSignal", testConditionSignal),
        ("testConditionTimeout", testConditionTimeout),
        ("testConditionBroadcastZero", testConditionBroadcastZero),
        ("testConditionBroadcastTen", testConditionBroadcastTen),
        ("testConditionBroadcastHundred", testConditionBroadcastHundred)
    ]
#endif
}
