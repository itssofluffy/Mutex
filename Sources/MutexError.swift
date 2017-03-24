/*
    MutexError.swift

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

public enum MutexError: Error {
    case MutexAttrInit(code: CInt)
    case MutexAttrSetType(code: CInt)
    case MutexInit(code: CInt)
    case MutexAttrDestroy(code: CInt)
    case MutexDestroy(code: CInt)
    case MutexLock(code: CInt)
    case MutexTryLock(code: CInt)
    case MutexUnlock(code: CInt)
    case InvalidTimeout
    case MutexSetPriorityCeiling(code: CInt)
    case MutexGetPriorityCeiling(code: CInt)

    case CondAttrInit(code: CInt)
    case CondInit(code: CInt)
    case CondAttrDestroy(code: CInt)
    case CondDestroy(code: CInt)
    case CondBroadcast(code: CInt)
    case CondSignal(code: CInt)
    case CondWait(code: CInt)
    case CondTimedWait(code: CInt)

    case NegativeWaitGroup(count: Int)
}

extension MutexError: CustomStringConvertible {
    public var description: String {
        func errorString(_ code: CInt) -> String {
            return String(cString: strerror(code)) + " (#\(code))"
        }

        switch self {
            case .MutexAttrInit(let code):
                return "pthread_mutexattr_init() failed: " + errorString(code)
            case .MutexAttrSetType(let code):
                return "pthread_mutexattr_settype() failed: " + errorString(code)
            case .MutexInit(let code):
                return "pthread_mutex_init() failed: " + errorString(code)
            case .MutexAttrDestroy(let code):
                return "pthread_mutexattr_destroy() failed: " + errorString(code)
            case .MutexDestroy(let code):
                return "pthread_mutex_destroy() failed: " + errorString(code)
            case .MutexLock(let code):
                return "pthread_mutex_lock() failed: " + errorString(code)
            case .MutexTryLock(let code):
                return "pthread_mutex_trylock() failed: " + errorString(code)
            case .MutexUnlock(let code):
                return "pthread_mutex_unlock() failed: " + errorString(code)
            case .InvalidTimeout:
                return "timeout must be > 0"
            case .MutexSetPriorityCeiling(let code):
                return "pthread_mutex_setprioceiling() failed: " + errorString(code)
            case .MutexGetPriorityCeiling(let code):
                return "pthread_mutex_getprioceiling() failed: " + errorString(code)
            case .CondAttrInit(let code):
                return "pthread_condattr_init() failed: " + errorString(code)
            case .CondInit(let code):
                return "pthread_cond_init() failed: " + errorString(code)
            case .CondAttrDestroy(let code):
                return "pthread_condattr_destroy() failed: " + errorString(code)
            case .CondDestroy(let code):
                return "pthread_cond_destroy() failed: " + errorString(code)
            case .CondBroadcast(let code):
                return "pthread_cond_broadcast() failed: " + errorString(code)
            case .CondSignal(let code):
                return "pthread_cond_signal() failed: " + errorString(code)
            case .CondWait(let code):
                return "pthread_cond_wait() failed: " + errorString(code)
            case .CondTimedWait(let code):
                return "pthread_cond_timedwait() failed: " + errorString(code)
            case .NegativeWaitGroup(let count):
                return "negative wait group count encountered: count=\(count)"
        }
    }
}
