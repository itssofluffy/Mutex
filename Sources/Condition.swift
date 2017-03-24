/*
    Condition.swift

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

import Glibc
import Foundation
import ISFLibrary

public class Condition {
    private var _attributes = pthread_condattr_t()
    private var _condition = pthread_cond_t()
    public let mutex: Mutex

    ///  Returns a new Cond.
    ///
    /// - Parameter:
    ///   - mutex:  A Mutex object.
    ///
    /// - Throws:   `MutexError.CondAttrInit`
    ///             `MutexError.CondInit`
    public init(_ mutex: Mutex) throws {
        self.mutex = mutex

        var returnCode = pthread_condattr_init(&_attributes)

        guard (returnCode == 0) else {
            throw MutexError.CondAttrInit(code: returnCode)
        }

        returnCode = pthread_cond_init(&_condition, &_attributes)

        guard (returnCode == 0) else {
            throw MutexError.CondInit(code: returnCode)
        }
    }

    deinit {
        wrapper(do: {
                    var returnCode = pthread_cond_destroy(&self._condition)

                    guard (returnCode == 0) else {
                        throw MutexError.CondDestroy(code: returnCode)
                    }

                    returnCode = pthread_condattr_destroy(&self._attributes)

                    guard (returnCode == 0) else {
                        throw MutexError.CondAttrDestroy(code: returnCode)
                    }
                },
                catch: { failure in
                    mutexErrorLogger(failure)
                })
    }

    /// Wakes all operations waiting on `Cond`.
    public func broadcast() throws {
        let returnCode = pthread_cond_broadcast(&_condition)

        guard (returnCode == 0) else {
            throw MutexError.CondBroadcast(code: returnCode)
        }
    }

    /// Wakes one operations waiting on `Cond`.
    public func signal() throws {
        let returnCode = pthread_cond_signal(&_condition)

        guard (returnCode == 0) else {
            throw MutexError.CondSignal(code: returnCode)
        }
    }

    @discardableResult
    public func wait(_ timeout: TimeInterval = -1) throws -> Wait {
        if (timeout < 0) {
            let returnCode = pthread_cond_wait(&_condition, &mutex.mutex)

            guard (returnCode == 0) else {
                throw MutexError.CondWait(code: returnCode)
            }
        } else {
            var tv = timeval()
            var ts = timespec()

            gettimeofday(&tv, nil)

            ts.tv_sec = time(nil) + timeout.wholeSeconds
            ts.tv_nsec = Int(tv.tv_usec * 1_000 + (1_000 * 1_000 * (timeout.milliseconds % 1_000)))
            ts.tv_sec += ts.tv_nsec / 1_000_000_000
            ts.tv_nsec %= 1_000_000_000

            let returnCode = pthread_cond_timedwait(&_condition, &mutex.mutex, &ts)

            guard (returnCode == 0) else {
                guard (returnCode == ETIMEDOUT) else {
                    throw MutexError.CondTimedWait(code: returnCode)
                }

                return .TimedOut
            }
        }

        return .Signaled
    }
}
