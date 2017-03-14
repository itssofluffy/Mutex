/*
    MutexLockTests.swift

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

class MutexLockTests: XCTestCase {
    func testMutexLockSimple() {
        var completed = false

        do {
            let mutex = try Mutex()

            try mutex.lock()
            try mutex.unlock()

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testMutexLockClosure() {
        var completed = false

        do {
            var result = 0
            let mutex = try Mutex()

            try mutex.lock {
                result = 1
            }

            XCTAssert(result == 1, "result == \(result)")

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testMutexLockDispatch() {
        var completed = false

        do {
            let count = 100
            let mutex = try Mutex()
            var total = 0
            let expectedTotal = makeTotal(count)
            let waitGroup = try WaitGroup()

            let closure = { (count: Int) -> Void in
                DispatchQueue(label: "com.mutex.test", qos: .background).async {
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

            try waitGroup.add(count)

            for i in 0 ..< count {
                closure(i)
            }

            try waitGroup.wait()

            XCTAssert(expectedTotal == total, "expected total is incorrect. expectedTotal: \(expectedTotal), total: \(total)")

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTryMutexLockSimple() {
        var completed = false

        do {
            let mutex = try Mutex()

            if (try mutex.tryLock() == .Failed) {
                XCTAssert(false, "tryLock() failed")
            }

            try mutex.unlock()

            try mutex.lock {
                if (try mutex.tryLock() == .Success) {
                    XCTAssert(false, "tryLock() success")
                }
            }

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTryMutexLockClosure() {
        var completed = false

        do {
            let mutex = try Mutex()

            let lockResult = try mutex.tryLock { () -> Int in
                return 1
            }

            XCTAssert(lockResult.lock == .Success, "lock = \(lockResult.lock)")
            XCTAssert(lockResult.result == 1, "result = \(lockResult.result)")

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTryMutexLockDispatch() {
        var completed = false

        do {
            let count = 100
            let mutex = try Mutex()
            var total = 0
            let expectedTotal = makeTotal(count)
            let waitGroup = try WaitGroup()

            let closure = { (count: Int) -> Void in
                DispatchQueue(label: "com.tryMutex.test", qos: .background).async {
                    wrapper(do: {
                                while (true) {
                                    if (try mutex.tryLock() == .Success) {
                                        total += count

                                        try mutex.unlock()

                                        try waitGroup.done()

                                        break
                                    }
                                }
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

            try waitGroup.wait()

            XCTAssert(expectedTotal == total, "expected total is incorrect. expectedTotal: \(expectedTotal), total: \(total)")

            completed = true
        } catch {
            XCTAssert(false, "\(error)")
        }

        XCTAssert(completed, "test not completed")
    }

#if !os(OSX)
    static let allTests = [
        ("testMutexLockSimple", testMutexLockSimple),
        ("testMutexLockClosure", testMutexLockClosure),
        ("testMutexLockDispatch", testMutexLockDispatch),
        ("testTryMutexLockSimple", testTryMutexLockSimple),
        ("testTryMutexLockClosure", testTryMutexLockClosure),
        ("testTryMutexLockDispatch", testTryMutexLockDispatch)
    ]
#endif
}
