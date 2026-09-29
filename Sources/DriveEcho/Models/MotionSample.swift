import Foundation

/// A single IMU reading containing accelerometer and gyroscope data.
public struct MotionSample: Sendable, Hashable, Codable {
    /// Accelerometer x-axis (g).
    public var ax: Double
    /// Accelerometer y-axis (g).
    public var ay: Double
    /// Accelerometer z-axis (g).
    public var az: Double
    /// Gyroscope x-axis (rad/s).
    public var gx: Double
    /// Gyroscope y-axis (rad/s).
    public var gy: Double
    /// Gyroscope z-axis (rad/s).
    public var gz: Double

    public init(
        ax: Double,
        ay: Double,
        az: Double,
        gx: Double,
        gy: Double,
        gz: Double
    ) {
        self.ax = ax
        self.ay = ay
        self.az = az
        self.gx = gx
        self.gy = gy
        self.gz = gz
    }
}
