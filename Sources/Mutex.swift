/*
    Mutex.swift

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

/// A mutual exclusion lock.
public class Mutex {
    public internal(set) var mutex = pthread_mutex_t()

    /// Returns a new Mutex.
    public init() throws {
        guard (pthread_mutex_init(&mutex, nil) >= 0) else {
            throw MutexError.MutexInit(code: errno)
        }
    }

    deinit {
        wrapper(do: {
                    guard (pthread_mutex_destroy(&self.mutex) >= 0) else {
                        throw MutexError.MutexDestroy(code: errno)
                    }
                },
                catch: { failure in
                    mutexLogger(failure)
                })
    }

    /// Locks the mutex before calling the throwing closure.
    ///
    /// - Throws:   `MutesError.MutexLock`
    public func lock() throws {
        guard (pthread_mutex_lock(&mutex) >= 0) else {
            throw MutexError.MutexLock(code: errno)
        }
    }

    /// Locks the mutex before calling the throwing closure. Unlocks after closure is completed
    ///
    /// - Parameters:
    ///   - closure:  The closure to call
    ///
    /// - Throws:   `MutesError.MutexLock`
    ///
    /// - Returns:  The generic type returned by the `closure`
    public func lock<T>(_ closure: @escaping () throws -> T) throws -> T {
        try lock()

        defer {
            wrapper(do: {
                        try self.unlock()
                    },
                    catch: { failure in
                        mutexLogger(failure)
                    })
        }

        return try closure()
    }

    /// Attempt to lock the mutex before calling the throwing closure. Unlocks after closure is completed
    ///
    /// - Throws:   `MutesError.MutexTryLock`
    ///
    /// - Returns:  The lock status.
    public func tryLock() throws -> Lock {
        let returnCode = pthread_mutex_trylock(&mutex)

        guard (returnCode == 0) else {
            guard (returnCode == EBUSY) else {
                throw MutexError.MutexTryLock(code: returnCode)
            }

            return .Failed
        }

        return .Success
    }

    /// Attempt to lock the mutex before calling the throwing closure. Unlocks after closure is completed
    ///
    /// - Parameters:
    ///   - closure:  The closure to call
    ///
    /// - Throws:   `MutesError.MutexTryLock`
    ///
    /// - Returns:  The lock status and closure return as a `LockResult`.
    public func tryLock<T>(_ closure: @escaping () throws -> T) throws -> LockResult<T> {
        guard (try tryLock() == .Success) else {
            return LockResult(lock: .Failed, result: nil)
        }

        defer {
            wrapper(do: {
                        try self.unlock()
                    },
                    catch: { failure in
                        mutexLogger(failure)
                    })
        }

        return try LockResult(lock: .Success, result: closure())
    }

    /// Attempt to lock the mutex with a timeout.
    ///
    /// - Parameters:
    ///   - timeout:  The timeout to use to obtain a lock.
    ///
    /// - Throws:   `MutexError.InvalidTimeout`
    ///             `MutesError.MutexTryLock`
    ///
    /// - Returns:  The lock status and closure return as a `LockResult`.
    public func tryLock(with timeout: TimeInterval) throws -> Lock {
        guard (timeout > 0) else {
            throw MutexError.InvalidTimeout
        }

        let timeoutAt = Date().timeIntervalSince1970 + timeout

        while (true) {
            if (Date().timeIntervalSince1970 >= timeoutAt) {
                break
            }

            if (try tryLock() == .Success) {
                return .Success
            }
        }

        return .Failed
    }

    /// Attempt to lock the mutex with a timeout before calling the throwing closure. Unlocks after closure is completed
    ///
    /// - Parameters:
    ///   - timeout:  The timeout to use to obtain a lock.
    ///   - closure:  The closure to call
    ///
    /// - Throws:   `MutexError.InvalidTimeout`
    ///             `MutesError.MutexTryLock`
    ///
    /// - Returns:  The lock status and closure return as a `LockResult`.
    public func tryLock<T>(with timeout: TimeInterval, _ closure: @escaping () throws -> T) throws -> LockResult<T> {
        if (try tryLock(with: timeout) == .Success) {
            defer {
                wrapper(do: {
                            try self.unlock()
                        },
                        catch: { failure in
                            mutexLogger(failure)
                        })
            }

            return try LockResult(lock: .Success, result: closure())
        }

        return LockResult(lock: .Failed, result: nil)
    }

    /// Is the mutex locked.
    ///
    /// - Throws:  `MutesError.MutexTryLock`
    ///            `MutesError.MutexUnLock`
    ///
    /// - Returns: The lock status.
    public func isLocked() throws -> Bool {
        let result = try tryLock()

        if (result == .Success) {
            try unlock()
        }

        return (result == .Failed) ? true : false
    }

    /// Attempt to unlock the mutex.
    ///
    /// - Throws:   `MutesError.MutexUnLock`
    public func unlock() throws {
        guard (pthread_mutex_unlock(&mutex) >= 0) else {
            throw MutexError.MutexUnlock(code: errno)
        }
    }

    public func setPriorityCeiling(_ ceiling: Int) throws -> Int {
        var oldCeiling = CInt.allZeros

        guard (pthread_mutex_setprioceiling(&mutex, CInt(ceiling), &oldCeiling) >= 0) else {
            throw MutexError.MutexSetPriorityCeiling(code: errno)
        }

        return Int(oldCeiling)
    }

    public func getPriorityCeiling() throws -> Int {
        var ceiling = CInt.allZeros

        guard (pthread_mutex_getprioceiling(&mutex, &ceiling) >= 0) else {
            throw MutexError.MutexGetPriorityCeiling(code: errno)
        }

        return Int(ceiling)
    }
}
