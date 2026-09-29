import Foundation

/// A provider of location samples, enabling dependency injection for
/// navigation code.
///
/// Use ``LiveLocationProvider`` in production and ``ReplayLocationProvider``
/// in tests and demos.
public protocol LocationProviding: Sendable {
    var locations: AsyncStream<LocationSample> { get }
}
