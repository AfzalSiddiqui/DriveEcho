import CoreLocation
import CoreMotion
import Foundation

/// Errors thrown by ``TraceRecorder``.
public enum TraceRecorderError: Error, Sendable {
    case alreadyRecording
    case notRecording
    case locationAuthorizationDenied
    case motionNotAvailable
}

/// Records GPS and motion data into a ``Trace``.
///
/// An actor that captures `CLLocation` and `CMDeviceMotion` into a single
/// timestamped trace. Safe to use from any task.
public actor TraceRecorder {
    public enum State: Sendable {
        case idle
        case recording
    }

    public private(set) var state: State = .idle

    private let configuration: RecorderConfiguration
    private var samples: [Sample] = []
    private var startDate: Date?
    private var referenceTime: TimeInterval?

    private var locationDelegate: LocationDelegate?
    private var locationManager: CLLocationManager?
    private var motionManager: CMMotionManager?
    private var collectionTask: Task<Void, Never>?

    public init(configuration: RecorderConfiguration = .init()) {
        self.configuration = configuration
    }

    /// Start recording GPS and motion data.
    public func start() throws {
        guard state == .idle else {
            throw TraceRecorderError.alreadyRecording
        }

        state = .recording
        samples = []
        startDate = Date()
        referenceTime = ProcessInfo.processInfo.systemUptime

        let delegate = LocationDelegate()
        let locManager = CLLocationManager()
        locManager.desiredAccuracy = configuration.locationAccuracy
        locManager.delegate = delegate
        locManager.startUpdatingLocation()
        self.locationDelegate = delegate
        self.locationManager = locManager

        let motManager = CMMotionManager()
        motManager.deviceMotionUpdateInterval = configuration.motionUpdateInterval
        motManager.startDeviceMotionUpdates()
        self.motionManager = motManager

        let interval = configuration.motionUpdateInterval
        let refTime = referenceTime!

        collectionTask = Task { [weak self] in
            // Merge location and motion into samples
            await withTaskGroup(of: Void.self) { group in
                // Location collection
                group.addTask {
                    for await location in delegate.stream {
                        let t = location.timestamp.timeIntervalSince1970
                            - (self != nil ? await self!.startDate!.timeIntervalSince1970 : 0)
                        let sample = Sample(
                            t: max(t, 0),
                            location: LocationSample(
                                lat: location.coordinate.latitude,
                                lon: location.coordinate.longitude,
                                alt: location.altitude,
                                hAcc: location.horizontalAccuracy,
                                speed: max(location.speed, 0),
                                course: location.course >= 0 ? location.course : 0
                            )
                        )
                        await self?.appendSample(sample)
                    }
                }

                // Motion collection (pull-based)
                group.addTask {
                    while !Task.isCancelled {
                        if let motion = motManager.deviceMotion {
                            let t = motion.timestamp - refTime
                            let sample = Sample(
                                t: max(t, 0),
                                motion: MotionSample(
                                    ax: motion.userAcceleration.x,
                                    ay: motion.userAcceleration.y,
                                    az: motion.userAcceleration.z,
                                    gx: motion.rotationRate.x,
                                    gy: motion.rotationRate.y,
                                    gz: motion.rotationRate.z
                                )
                            )
                            await self?.appendSample(sample)
                        }
                        try? await Task.sleep(for: .seconds(interval))
                    }
                }
            }
        }
    }

    /// Stop recording and return the captured trace.
    public func stop() throws -> Trace {
        guard state == .recording else {
            throw TraceRecorderError.notRecording
        }

        collectionTask?.cancel()
        collectionTask = nil
        locationManager?.stopUpdatingLocation()
        locationDelegate?.stop()
        motionManager?.stopDeviceMotionUpdates()

        locationManager = nil
        locationDelegate = nil
        motionManager = nil

        state = .idle

        let trace = Trace(
            device: Self.deviceIdentifier(),
            recordedAt: startDate ?? .now,
            samples: samples.sorted { $0.t < $1.t }
        )
        samples = []
        return trace
    }

    private func appendSample(_ sample: Sample) {
        samples.append(sample)
    }

    private static func deviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.compactMap { child -> String? in
            guard let value = child.value as? Int8, value != 0 else { return nil }
            return String(UnicodeScalar(UInt8(value)))
        }.joined()
    }
}

// MARK: - Location Delegate

/// Bridges CLLocationManagerDelegate callbacks to an AsyncStream.
final class LocationDelegate: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    let stream: AsyncStream<CLLocation>
    private let continuation: AsyncStream<CLLocation>.Continuation

    override init() {
        (stream, continuation) = AsyncStream.makeStream(of: CLLocation.self)
        super.init()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        for location in locations {
            continuation.yield(location)
        }
    }

    func stop() {
        continuation.finish()
    }
}
