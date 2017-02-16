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
import ISFLibrary

/// A mutual exclusion lock.
public class Mutex {
    public internal(set) var mutex = pthread_mutex_t()

    /// Returns a new Mutex.
    public init() throws {
        let returnCode = pthread_mutex_init(&mutex, nil)

        guard (returnCode == 0) else {
            throw MutexError.MutexInit(code: errno)
        }
    }

    deinit {
        let returnCode = pthread_mutex_destroy(&mutex)

        guard (returnCode == 0) else {
            let errorNumber = errno
            let errorString = String(cString: strerror(errorNumber))
            let dynamicType = type(of: self)

            print("\(dynamicType).\(#function).pthread_mutex_destory() failed: \(errorString) (#\(errorNumber))", to: &errorStream)

            return
        }
    }

    /// Locks the mutex. If the lock is already in use, the calling operation blocks until the mutex is available.
    public func lock() throws {
        let returnCode = pthread_mutex_lock(&mutex)

        guard (returnCode == 0) else {
            throw MutexError.MutexLock(code: errno)
        }
    }

    /// Locks the mutex before calling the function. Unlocks after closure is completed
    public func lock(_ closureHandler: () -> Void) throws {
        try lock()

        closureHandler()

        try unlock()
    }

    public func lock(_ closureHandler: () throws -> Void) throws {
        try lock()

        defer {
            do {
                try unlock()
            } catch {
                let dynamicType = type(of: self)

                print("\(dynamicType).\(#function) failed: \(error)", to: &errorStream)
            }
        }

        try closureHandler()
    }

    public func tryLock() throws -> TryLockResult {
        let returnCode = pthread_mutex_trylock(&mutex)

        guard (returnCode == 0) else {
            let errorNumber = errno

            if (errorNumber == EBUSY) {
                return .Failed
            }

            throw MutexError.MutexTryLock(code: errorNumber)
        }

        return .Success
    }

    @discardableResult
    public func tryLock(_ closureHandler: () -> Void) throws -> TryLockResult {
        let result = try tryLock()

        guard (result == .Success) else {
            return result
        }

        closureHandler()

        try unlock()

        return .Success
    }

    @discardableResult
    public func tryLock(_ closureHandler: () throws -> Void) throws -> TryLockResult {
        let result = try tryLock()

        guard (result == .Success) else {
            return result
        }

        defer {
            do {
                try unlock()
            } catch {
                let dynamicType = type(of: self)

                print("\(dynamicType).\(#function) failed: \(error)", to: &errorStream)
            }
        }

        try closureHandler()

        return .Success
    }

    public func unlock() throws {
        let returnCode = pthread_mutex_unlock(&mutex)

        guard (returnCode == 0) else {
            throw MutexError.MutexUnlock(code: errno)
        }
    }

    public func setPriorityCeiling(_ ceiling: Int) throws -> Int {
        var oldCeiling = CInt.allZeros

        let returnCode = pthread_mutex_setprioceiling(&mutex, CInt(ceiling), &oldCeiling)

        guard (returnCode == 0) else {
            throw MutexError.MutexSetPriorityCeiling(code: errno)
        }

        return Int(oldCeiling)
    }

    public func getPriorityCeiling() throws -> Int {
        var ceiling = CInt.allZeros

        let returnCode = pthread_mutex_getprioceiling(&mutex, &ceiling)

        guard (returnCode == 0) else {
            throw MutexError.MutexGetPriorityCeiling(code: errno)
        }

        return Int(ceiling)
    }
}
