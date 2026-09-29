import Foundation

/// A single timestamped sample containing optional GPS and IMU data.
public struct Sample: Sendable, Hashable, Codable {
    /// Time offset in seconds from the start of the trace.
    public var t: TimeInterval

    /// GPS fix at this point. `nil` during tunnel or signal-loss perturbations.
    public var location: LocationSample?

    /// IMU reading at this point. `nil` if motion was not recorded.
    public var motion: MotionSample?

    public init(
        t: TimeInterval,
        location: LocationSample? = nil,
        motion: MotionSample? = nil
    ) {
        self.t = t
        self.location = location
        self.motion = motion
    }
}
