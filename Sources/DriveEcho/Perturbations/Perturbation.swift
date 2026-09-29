import Foundation

/// A deterministic transformation applied to a ``Trace`` to simulate
/// real-world GPS conditions.
public enum Perturbation: Sendable, Hashable {
    /// Drop GPS fixes within a time window, simulating a tunnel.
    /// Motion data is preserved.
    case tunnel(start: Duration, duration: Duration)

    /// Gradually offset position by the given number of meters
    /// over the specified duration from the start of the trace.
    case drift(meters: Double, over: Duration)

    /// Add Gaussian noise to GPS coordinates.
    /// Uses a fixed seed for deterministic, reproducible results.
    case jitter(sigmaMeters: Double, seed: UInt64)
}
