import ISFLibrary

public class Once {
    private let mutex: Mutex
    private var done = false

    public init() throws {
        self.mutex = try Mutex()
    }

    public func execute(_ closureHandler: () -> Void) throws {
        try self.mutex.lock()

        defer {
            do {
                try self.mutex.unlock()
            } catch {
                let dynamicType = type(of: self)

                print("\(dynamicType).\(#function) failed: \(error))", to: &errorStream)
            }
        }

        if (!self.done) {
            self.done = true
            closureHandler()
        }
    }

    //
    public func execute(_ closureHandler: () throws -> Void) throws {
        try self.mutex.lock()

        defer {
            do {
                try self.mutex.unlock()
            } catch {
                let dynamicType = type(of: self)

                print("\(dynamicType).\(#function) failed: \(error))", to: &errorStream)
            }
        }

        if (!self.done) {
            self.done = true
            try closureHandler()
        }
    }
}
