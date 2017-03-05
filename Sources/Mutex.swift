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

        guard (returnCode >= 0) else {
            throw MutexError.MutexInit(code: errno)
        }
    }

    deinit {
        doCatchWrapper(funcCall: {
                           let returnCode = pthread_mutex_destroy(&self.mutex)

                           guard (returnCode >= 0) else {
                               throw MutexError.MutexDestroy(code: errno)
                           }
                       },
                       failed:  { failure in
                           mutexLogger(failure)
                       })
    }

    /// Locks the mutex before calling the throwing closure. Unlocks after closure is completed
    public func lock<T>(_ closureHandler: @escaping () throws -> T?) throws -> T? {
        let returnCode = pthread_mutex_lock(&mutex)

        guard (returnCode >= 0) else {
            throw MutexError.MutexLock(code: errno)
        }

        defer {
            doCatchWrapper(funcCall: {
                               try self.unlock()
                           },
                           failed:  { failure in
                               mutexLogger(failure)
                           })
        }

        return try closureHandler()
    }

    /// Attempt to Lock the mutex before calling the throwing closure. Unlocks after closure is completed
    public func tryLock<T>(_ closureHandler: @escaping () throws -> T?) throws -> TryLockResult<T> {
        let returnCode = pthread_mutex_trylock(&mutex)

        guard (returnCode >= 0) else {
            let errorNumber = errno

            guard (errorNumber == EBUSY) else {
                throw MutexError.MutexTryLock(code: errorNumber)
            }

            return TryLockResult(lock: .Failed, result: nil)
        }

        defer {
            doCatchWrapper(funcCall: {
                               try self.unlock()
                           },
                           failed:  { failure in
                               mutexLogger(failure)
                           })
        }

        let result = try closureHandler()

        return TryLockResult(lock: .Success, result: result)
    }

    public func unlock() throws {
        let returnCode = pthread_mutex_unlock(&mutex)

        guard (returnCode >= 0) else {
            throw MutexError.MutexUnlock(code: errno)
        }
    }

    public func setPriorityCeiling(_ ceiling: Int) throws -> Int {
        var oldCeiling = CInt.allZeros

        let returnCode = pthread_mutex_setprioceiling(&mutex, CInt(ceiling), &oldCeiling)

        guard (returnCode >= 0) else {
            throw MutexError.MutexSetPriorityCeiling(code: errno)
        }

        return Int(oldCeiling)
    }

    public func getPriorityCeiling() throws -> Int {
        var ceiling = CInt.allZeros

        let returnCode = pthread_mutex_getprioceiling(&mutex, &ceiling)

        guard (returnCode >= 0) else {
            throw MutexError.MutexGetPriorityCeiling(code: errno)
        }

        return Int(ceiling)
    }
}
