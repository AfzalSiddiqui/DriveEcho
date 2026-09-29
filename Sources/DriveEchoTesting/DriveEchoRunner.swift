import DriveEcho
import Foundation

/// A protocol that navigators must conform to for test replay.
public protocol DriveEchoNavigable: Sendable {
    /// Process a single sample from the replayed trace.
    func update(location: LocationSample?, motion: MotionSample?) async
    /// Stream of navigation events emitted during processing.
    var events: AsyncStream<NavigationEvent> { get }
}

/// Replays a trace through a navigator and collects the results.
public enum DriveEchoRunner {
    /// Run a trace through a navigator at the given speed and collect events.
    /// - Parameters:
    ///   - trace: The trace to replay.
    ///   - navigator: The navigator to test.
    ///   - speed: Playback speed multiplier (default 1.0).
    /// - Returns: A ``RunResult`` containing the collected events.
    public static func run(
        _ trace: Trace,
        through navigator: some DriveEchoNavigable,
        speed: Double = 1.0
    ) async throws -> RunResult {
        let player = TracePlayer(trace: trace, speed: speed)

        let eventTask = Task {
            var collected: [NavigationEvent] = []
            for await event in navigator.events {
                collected.append(event)
            }
            return collected
        }

        for await sample in player.samples {
            await navigator.update(location: sample.location, motion: sample.motion)
        }

        // Give the navigator a moment to emit final events
        try? await Task.sleep(for: .milliseconds(50))
        eventTask.cancel()

        let events = await eventTask.value

        return RunResult(
            trace: trace,
            events: events,
            totalDuration: trace.duration
        )
    }
}
