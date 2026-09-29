import CoreLocation
import Foundation

/// Configuration for a ``TraceRecorder``.
public struct RecorderConfiguration: Sendable {
    /// Desired location accuracy (e.g. `kCLLocationAccuracyBestForNavigation`).
    public var locationAccuracy: CLLocationAccuracy

    /// Interval between IMU samples in seconds (e.g. 0.02 for 50 Hz).
    public var motionUpdateInterval: TimeInterval

    public init(
        locationAccuracy: CLLocationAccuracy = kCLLocationAccuracyBestForNavigation,
        motionUpdateInterval: TimeInterval = 0.02
    ) {
        self.locationAccuracy = locationAccuracy
        self.motionUpdateInterval = motionUpdateInterval
    }
}
