/*
    MutexType.swift

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

import Glibc

public enum MutexType {
    case Default      // Attempting to recursively lock a mutex of this type results in undefined behavior.
                      // Attempting to unlock a mutex of this type which was not locked by the calling thread
                      // results in undefined behavior.
                      // Attempting to unlock a mutex of this type which is not locked results in undefined
                      // behavior. An implementation may map this mutex to one of the other mutex types.
    case Normal       // This type of mutex does not detect deadlock. A thread attempting to relock this mutex
                      // without first unlocking it shall deadlock. Attempting to unlock a mutex locked by a
                      // different thread results in undefined behavior. Attempting to unlock an unlocked mutex
                      // results in undefined behavior.
    case ErrorCheck   // This type of mutex provides error checking. A thread attempting to relock this mutex
                      // without first unlocking it shall return with an error. A thread attempting to unlock a
                      // mutex which another thread has locked shall return with an error. A thread attempting
                      // to unlock an unlocked mutex shall return with an error.
    case Recursive    // A thread attempting to relock this mutex without first unlocking it shall succeed in
                      // locking the mutex. The relocking deadlock which can occur with mutexes of type
                      // PTHREAD_MUTEX_NORMAL cannot occur with this type of mutex. Multiple locks of this mutex
                      // shall require the same number of unlocks to release the mutex before another thread can
                      // acquire the mutex. A thread attempting to unlock a mutex which another thread has locked
                      // shall return with an error. A thread attempting to unlock an unlocked mutex shall return
                      // with an error.

    public var rawValue: CInt {
        switch self {
            case .Default:
                return CInt(PTHREAD_MUTEX_DEFAULT)
            case .Normal:
                return CInt(PTHREAD_MUTEX_NORMAL)
            case .ErrorCheck:
                return CInt(PTHREAD_MUTEX_ERRORCHECK)
            case .Recursive:
                return CInt(PTHREAD_MUTEX_RECURSIVE)
        }
    }
}
