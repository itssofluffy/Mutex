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
        self.condition = try Condition(mutex: Mutex())
    }

    public func add(_ delta: Int) throws {
        try self.condition.mutex.lock()

        defer {
            do {
                try self.condition.mutex.unlock()
            } catch {
                let dynamicType = type(of: self)

                print("\(dynamicType).\(#function) failed: \(error)", to: &errorStream)
            }
        }

        self.count += delta

        if (self.count < 0) {
            throw MutexError.NegativeWaitGroup(count: self.count)
        }

        try self.condition.broadcast()
    }

    /// Decrements the WaitGroup counter.
    public func done() throws {
        try self.add(-1)
    }

    /// Blocks until the WaitGroup counter is Zero.
    public func wait() throws {
        try self.condition.mutex.lock()

        defer {
            do {
                try self.condition.mutex.unlock()
            } catch {
                let dynamicType = type(of: self)

                print("\(dynamicType).\(#function) failed: \(error)", to: &errorStream)
            }
        }

        while (self.count > 0) {
            try self.condition.wait()
        }
    }
}
