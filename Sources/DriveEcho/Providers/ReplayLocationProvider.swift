import Foundation

/// A ``LocationProviding`` implementation that replays locations from a
/// recorded ``Trace``, useful for tests and demos.
public struct ReplayLocationProvider: LocationProviding {
    /// Stream of replayed location samples with timing delays.
    public let locations: AsyncStream<LocationSample>

    /// Create a replay provider.
    /// - Parameters:
    ///   - trace: The trace to replay locations from.
    ///   - speed: Playback speed multiplier (default 1.0).
    public init(trace: Trace, speed: Double = 1.0) {
        let samples = trace.samples
        let playbackSpeed = speed

        locations = AsyncStream { continuation in
            let task = Task {
                var lastT: TimeInterval?
                for sample in samples {
                    guard let location = sample.location else { continue }

                    if let prev = lastT {
                        let delay = (sample.t - prev) / playbackSpeed
                        if delay > 0 {
                            try? await Task.sleep(for: .seconds(delay))
                        }
                    }
                    lastT = sample.t
                    continuation.yield(location)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
