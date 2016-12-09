/// The WaitResult enum is used as a return value by Mutex.wait()
public enum WaitResult {
    case Signaled   // The wait resulted in a signal
    case TimedOut   // The wait resulted in a timeout
}
