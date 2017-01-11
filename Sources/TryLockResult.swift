public enum TryLockResult {
    case Failed     // The mutex could not be locked because it was already locked
    case Success    // The mutex was locked
}

extension TryLockResult: CustomStringConvertible {
    public var description: String {
        switch self {
            case .Failed:
                return "failed"
            case .Success:
                return "success"
        }
    }
}
