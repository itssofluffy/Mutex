import Glibc
import ISFLibrary

/// A mutual exclusion lock.
public class Mutex {
    public internal(set) var mutex = pthread_mutex_t()

    /// Returns a new Mutex.
    public init() throws {
        let returnCode = pthread_mutex_init(&self.mutex, nil)

        guard (returnCode == 0) else {
            throw MutexError.MutexInit(code: errno)
        }
    }

    deinit {
        let returnCode = pthread_mutex_destroy(&self.mutex)

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
        let returnCode = pthread_mutex_lock(&self.mutex)

        guard (returnCode == 0) else {
            throw MutexError.MutexLock(code: errno)
        }
    }

    /// Locks the mutex before calling the function. Unlocks after closure is completed
    public func lock(_ closureHandler: () -> Void) throws {
        try self.lock()

        closureHandler()

        try self.unlock()
    }

    public func lock(_ closureHandler: () throws -> Void) throws {
        try self.lock()

        defer {
            do {
                try self.unlock()
            } catch {
                let dynamicType = type(of: self)

                print("\(dynamicType).\(#function) failed: \(error)", to: &errorStream)
            }
        }

        try closureHandler()
    }

    public func tryLock() throws -> TryLockResult {
        let returnCode = pthread_mutex_trylock(&self.mutex)

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
        let result = try self.tryLock()

        guard (result == .Success) else {
            return result
        }

        closureHandler()

        try self.unlock()

        return .Success
    }

    @discardableResult
    public func tryLock(_ closureHandler: () throws -> Void) throws -> TryLockResult {
        let result = try self.tryLock()

        guard (result == .Success) else {
            return result
        }

        defer {
            do {
                try self.unlock()
            } catch {
                let dynamicType = type(of: self)

                print("\(dynamicType).\(#function) failed: \(error)", to: &errorStream)
            }
        }

        try closureHandler()

        return .Success
    }

    public func unlock() throws {
        let returnCode = pthread_mutex_unlock(&self.mutex)

        guard (returnCode == 0) else {
            throw MutexError.MutexUnlock(code: errno)
        }
    }

    public func setPriorityCeiling(_ ceiling: Int) throws -> Int {
        var oldCeiling = CInt.allZeros

        let returnCode = pthread_mutex_setprioceiling(&self.mutex, CInt(ceiling), &oldCeiling)

        guard (returnCode == 0) else {
            throw MutexError.MutexSetPriorityCeiling(code: errno)
        }

        return Int(oldCeiling)
    }

    public func getPriorityCeiling() throws -> Int {
        var ceiling = CInt.allZeros

        let returnCode = pthread_mutex_getprioceiling(&self.mutex, &ceiling)

        guard (returnCode == 0) else {
            throw MutexError.MutexGetPriorityCeiling(code: errno)
        }

        return Int(ceiling)
    }
}
