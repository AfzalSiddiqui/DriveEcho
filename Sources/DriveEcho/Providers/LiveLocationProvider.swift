import CoreLocation
import Foundation

/// A ``LocationProviding`` implementation that wraps `CLLocationManager`
/// for production use.
public final class LiveLocationProvider: NSObject, LocationProviding,
    CLLocationManagerDelegate, @unchecked Sendable
{
    private let manager: CLLocationManager
    private let continuation: AsyncStream<LocationSample>.Continuation

    /// Stream of live GPS location samples.
    public let locations: AsyncStream<LocationSample>

    /// Create a live location provider.
    /// - Parameter accuracy: Desired location accuracy.
    public init(accuracy: CLLocationAccuracy = kCLLocationAccuracyBestForNavigation) {
        let (stream, cont) = AsyncStream.makeStream(of: LocationSample.self)
        self.locations = stream
        self.continuation = cont
        self.manager = CLLocationManager()
        super.init()
        manager.desiredAccuracy = accuracy
        manager.delegate = self
        manager.startUpdatingLocation()
    }

    deinit {
        manager.stopUpdatingLocation()
        continuation.finish()
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        for cl in locations {
            let sample = LocationSample(
                lat: cl.coordinate.latitude,
                lon: cl.coordinate.longitude,
                alt: cl.altitude,
                hAcc: cl.horizontalAccuracy,
                speed: max(cl.speed, 0),
                course: cl.course >= 0 ? cl.course : 0
            )
            continuation.yield(sample)
        }
    }
}
