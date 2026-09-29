import Foundation

/// Playback state for a ``TracePlayer``.
public enum PlayerState: Sendable {
    case idle
    case playing
    case paused
    case finished
}

/// Replays a ``Trace`` as an `AsyncStream` at configurable speed.
///
/// An actor that emits samples with timing proportional to the original
/// recording, divided by the speed multiplier. Safe to use from any task.
public actor TracePlayer {
    public private(set) var state: PlayerState = .idle

    private let trace: Trace
    private let speed: Double
    private var currentIndex: Int = 0

    /// Create a player for the given trace.
    /// - Parameters:
    ///   - trace: The trace to replay.
    ///   - speed: Playback speed multiplier (must be > 0 and <= 20).
    public init(trace: Trace, speed: Double = 1.0) {
        precondition(speed > 0 && speed <= 20, "Speed must be between 0 (exclusive) and 20 (inclusive)")
        self.trace = trace
        self.speed = speed
    }

    /// An `AsyncStream` that emits samples at the appropriate pace.
    ///
    /// Each access creates a fresh playback from the beginning.
    /// Usage: `for await sample in player.samples { ... }`
    public nonisolated var samples: AsyncStream<Sample> {
        let trace = self.trace
        let speed = self.speed
        let player = self

        return AsyncStream { continuation in
            let task = Task {
                await player.setState(.playing)

                for i in 0..<trace.samples.count {
                    let currentState = await player.state
                    if currentState == .finished { break }

                    // Wait while paused
                    while await player.state == .paused {
                        try? await Task.sleep(for: .milliseconds(50))
                    }

                    // Delay between samples
                    if i > 0 {
                        let delay = (trace.samples[i].t - trace.samples[i - 1].t) / speed
                        if delay > 0 {
                            try? await Task.sleep(for: .seconds(delay))
                        }
                    }

                    continuation.yield(trace.samples[i])
                    await player.setIndex(i)
                }

                await player.setState(.finished)
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Pause playback.
    public func pause() {
        guard state == .playing else { return }
        state = .paused
    }

    /// Resume playback after a pause.
    public func resume() {
        guard state == .paused else { return }
        state = .playing
    }

    /// Seek to the sample closest to the given time offset.
    public func seek(to time: TimeInterval) {
        currentIndex = trace.samples.firstIndex(where: { $0.t >= time })
            ?? trace.samples.count
    }

    // MARK: - Internal

    private func setState(_ newState: PlayerState) {
        state = newState
    }

    private func setIndex(_ index: Int) {
        currentIndex = index
    }
}
