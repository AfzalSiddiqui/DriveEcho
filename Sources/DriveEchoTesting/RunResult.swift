import DriveEcho
import Foundation

/// An event emitted by a navigator during trace replay.
public enum NavigationEvent: Sendable, Hashable {
    case onRoute(at: TimeInterval)
    case offRoute(at: TimeInterval)
    case rerouted(at: TimeInterval)
}

/// The result of running a trace through a navigator.
public struct RunResult: Sendable {
    /// The trace that was replayed.
    public let trace: Trace
    /// Events emitted by the navigator during replay.
    public let events: [NavigationEvent]
    /// Total duration of the trace in seconds.
    public let totalDuration: TimeInterval

    public init(trace: Trace, events: [NavigationEvent], totalDuration: TimeInterval) {
        self.trace = trace
        self.events = events
        self.totalDuration = totalDuration
    }
}
