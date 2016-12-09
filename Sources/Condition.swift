import Glibc
import Foundation
import ISFLibrary

public class Condition {
    private var condition = pthread_cond_t()
    public let mutex: Mutex

    ///  Returns a new Cond.
    /// - Parameter mutex: A Mutex object.
    public init(mutex: Mutex) throws {
        self.mutex = mutex

        let returnCode = pthread_cond_init(&self.condition, nil)

        guard (returnCode == 0) else {
            throw MutexError.CondInit(code: errno)
        }
    }

    deinit {
        let returnCode = pthread_cond_destroy(&self.condition)

        if (returnCode != 0) {
            let errorNumber = errno
            let errorString = String(cString: strerror(errorNumber))
            let dynamicType = type(of: self)

            print("\(dynamicType).\(#function).pthread_cond_destory() failed: \(errorString) (#\(errorNumber))", to: &errorStream)
        }
    }

    /// Wakes all operations waiting on `Cond`.
    public func broadcast() throws {
        let returnCode = pthread_cond_broadcast(&self.condition)

        guard (returnCode == 0) else {
            throw MutexError.CondBroadcast(code: errno)
        }
    }

    /// Wakes one operations waiting on `Cond`.
    public func signal() throws {
        let returnCode = pthread_cond_signal(&self.condition)

        guard (returnCode == 0) else {
            throw MutexError.CondSignal(code: errno)
        }
    }

    @discardableResult
    public func wait(seconds: TimeInterval = -1) throws -> WaitResult {
        if (seconds < 0) {
            let returnCode = pthread_cond_wait(&self.condition, &self.mutex.mutex)

            guard (returnCode == 0) else {
                throw MutexError.CondWait(code: errno)
            }
        } else {
            var tv = timeval()
            var ts = timespec()

            gettimeofday(&tv, nil)

            ts.tv_sec = time(nil) + seconds.asSeconds
            ts.tv_nsec = Int(tv.tv_usec * 1000 + (1000 * 1000 * (seconds.asMilliseconds % 1000)))
            ts.tv_sec += ts.tv_nsec / 1000000000
            ts.tv_nsec %= 1000000000

            let returnCode = pthread_cond_timedwait(&self.condition, &self.mutex.mutex, &ts)

            guard (returnCode == 0) else {
                let errorNumber = errno

                if (errorNumber == ETIMEDOUT) {
                    return .TimedOut
                }

                throw MutexError.CondTimedWait(code: errorNumber)
            }
        }

        return .Signaled
    }
}
