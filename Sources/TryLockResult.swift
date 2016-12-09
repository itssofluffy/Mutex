public enum TryLockResult {
    case NotLocked    // The mutex could not be locked because it was already locked
    case Locked       // The mutex was locked
}
