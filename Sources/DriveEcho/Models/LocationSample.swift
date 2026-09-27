import Foundation

/// A single GPS fix containing position, accuracy, speed and course.
public struct LocationSample: Sendable, Hashable, Codable {
    /// Latitude in degrees.
    public var lat: Double
    /// Longitude in degrees.
    public var lon: Double
    /// Altitude in meters.
    public var alt: Double
    /// Horizontal accuracy in meters.
    public var hAcc: Double
    /// Speed in meters per second.
    public var speed: Double
    /// Course (heading) in degrees, where 0 is true north.
    public var course: Double

    public init(
        lat: Double,
        lon: Double,
        alt: Double,
        hAcc: Double,
        speed: Double,
        course: Double
    ) {
        self.lat = lat
        self.lon = lon
        self.alt = alt
        self.hAcc = hAcc
        self.speed = speed
        self.course = course
    }
}
