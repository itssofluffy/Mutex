/*
    WaitGroup.swift

    Copyright (c) 2016, 2017 Stephen Whittle  All rights reserved.

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

import ISFLibrary

public class WaitGroup {
    private let condition: Condition
    private var count = 0

    public init() throws {
        condition = try Condition(mutex: Mutex())
    }

    public func add(_ delta: Int) throws {
        try condition.mutex.lock()

        defer {
            doCatchWrapper(funcCall: {
                               try self.condition.mutex.unlock()
                           },
                           failed:  { failure in
                               mutexLogger(failure)
                           })
        }

        count += delta

        if (count < 0) {
            throw MutexError.NegativeWaitGroup(count: count)
        }

        try condition.broadcast()
    }

    /// Decrements the WaitGroup counter.
    public func done() throws {
        try add(-1)
    }

    /// Blocks until the WaitGroup counter is Zero.
    public func wait() throws {
        try condition.mutex.lock()

        defer {
            doCatchWrapper(funcCall: {
                               try self.condition.mutex.unlock()
                           },
                           failed:  { failure in
                               mutexLogger(failure)
                           })
        }

        while (count > 0) {
            try condition.wait()
        }
    }
}
