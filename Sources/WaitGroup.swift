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
