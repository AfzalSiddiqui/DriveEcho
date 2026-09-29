import Foundation

/// A recorded drive trace containing timestamped GPS and motion samples.
public struct Trace: Sendable, Hashable, Codable {
    /// Format version.
    public var version: Int

    /// Device identifier (e.g. "iPhone15,2").
    public var device: String

    /// When the trace was recorded.
    public var recordedAt: Date

    /// Timestamped samples ordered by time offset.
    public var samples: [Sample]

    public init(
        version: Int = 1,
        device: String,
        recordedAt: Date = .now,
        samples: [Sample]
    ) {
        self.version = version
        self.device = device
        self.recordedAt = recordedAt
        self.samples = samples
    }

    /// Total duration of the trace in seconds.
    public var duration: TimeInterval {
        samples.last?.t ?? 0
    }
}
