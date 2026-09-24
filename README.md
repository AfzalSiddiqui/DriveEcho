# DriveEcho

**Record real drives once, then replay the GPS and motion traces to test iOS navigation code, with tunnel and GPS drift simulation.**

![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange) ![Platforms](https://img.shields.io/badge/platforms-iOS%2016%2B-blue) ![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen) ![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Why DriveEcho?

Navigation logic is hard to test. Route snapping, off-route detection, rerouting and dead reckoning all depend on real-world sensor data, and the only way to reproduce a bug is usually to drive the same road again.

DriveEcho removes the car from the loop:

1. **Record** a drive on a real device: GPS fixes plus accelerometer and gyroscope samples, all timestamped.
2. **Replay** the trace in unit tests, the simulator or on device, at 1x or up to 20x speed.
3. **Perturb** the trace to simulate tunnels, signal loss, urban-canyon multipath and GPS drift.
4. **Assert** on what your navigation code did, the same way every time.

## Features

- 📍 **Recorder**: captures `CLLocation` and `CMDeviceMotion` into a single timestamped trace.
- ▶️ **Player**: replays traces as an `AsyncStream` at configurable speed, with pause, resume and seek.
- 🚇 **Perturbations**: tunnel dropouts, signal loss, drift, jitter and accuracy degradation, all deterministic with a seed.
- 🧪 **Testing helpers**: a `DriveEchoTesting` target with XCTest assertions for on-route and off-route checks.
- 📂 **Formats**: native JSON traces, GPX import and GeoJSON export.
- 🔌 **Drop-in provider**: a `LocationProviding` protocol so your code works with live GPS in production and replayed traces in tests.
- 🧵 **Concurrency-safe**: built on Swift Concurrency, with `Sendable` types throughout.
- 📚 **Documented**: full DocC reference and a sample app.

## Requirements

| | Minimum |
|---|---|
| iOS | 16.0 |
| Swift | 5.9 |
| Xcode | 15 |

## Installation

### Swift Package Manager

In Xcode choose **File → Add Package Dependencies…** and enter:

```
https://github.com/AfzalSiddiqui/DriveEcho
```

Or add it to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AfzalSiddiqui/DriveEcho", from: "0.1.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["DriveEcho"]),
    .testTarget(name: "YourAppTests", dependencies: ["DriveEcho", .product(name: "DriveEchoTesting", package: "DriveEcho")])
]
```

## Quick start

### 1. Record a drive

Add `NSLocationWhenInUseUsageDescription` and `NSMotionUsageDescription` to your `Info.plist`. Enable the **Location updates** background mode if you want to record with the screen off.

```swift
import DriveEcho

let recorder = TraceRecorder(configuration: .init(
    locationAccuracy: .bestForNavigation,
    motionUpdateInterval: 0.02   // 50 Hz IMU
))

try await recorder.start()
// ... drive ...
let trace = try await recorder.stop()

try trace.write(to: documentsURL.appending(path: "sheikh-zayed-road.driveecho.json"))
```

### 2. Replay it

```swift
let trace = try Trace(contentsOf: traceURL)
let player = TracePlayer(trace: trace, speed: 5.0)

for await sample in player.samples {
    navigator.update(location: sample.location, motion: sample.motion)
}
```

### 3. Simulate a tunnel

```swift
let tunnelled = trace.perturbed(with: [
    .tunnel(start: .seconds(120), duration: .seconds(45)),   // no GPS, IMU keeps running
    .drift(meters: 25, over: .seconds(30)),
    .jitter(sigmaMeters: 4, seed: 42)
])
```

### 4. Use it in your app through `LocationProviding`

```swift
public protocol LocationProviding: Sendable {
    var locations: AsyncStream<LocationSample> { get }
}

// Production
let provider: LocationProviding = LiveLocationProvider()

// Tests and demos
let provider: LocationProviding = ReplayLocationProvider(trace: trace, speed: 10)
```

## Testing navigation code

```swift
import XCTest
import DriveEcho
import DriveEchoTesting

final class OffRouteDetectionTests: XCTestCase {

    func test_rerouteTriggered_whenDriverMissesExit() async throws {
        let trace = try Trace.fixture(named: "missed-exit-e11")
        let navigator = Navigator(route: .fixture(named: "e11-to-marina"))

        let result = try await DriveEchoRunner.run(trace, through: navigator, speed: 20)

        XCTAssertRerouted(result, within: .seconds(10), afterLeavingRouteAt: .seconds(212))
    }

    func test_staysOnRoute_throughTunnel() async throws {
        let trace = try Trace.fixture(named: "airport-tunnel")
            .perturbed(with: [.tunnel(start: .seconds(60), duration: .seconds(90))])

        let result = try await DriveEchoRunner.run(trace, through: Navigator(route: .fixture(named: "airport-tunnel")))

        XCTAssertStaysOnRoute(result, toleranceMeters: 30)
    }
}
```

Every perturbation uses a fixed seed, so a failing test fails the same way on every machine and in CI.

## Trace format

Traces are plain JSON, so they're easy to diff, share and commit as test fixtures.

```json
{
  "version": 1,
  "device": "iPhone15,2",
  "recordedAt": "2026-09-26T08:14:03Z",
  "samples": [
    {
      "t": 0.000,
      "location": { "lat": 25.2048, "lon": 55.2708, "alt": 12.1, "hAcc": 4.8, "speed": 16.2, "course": 42.5 },
      "motion": { "ax": 0.01, "ay": -0.03, "az": -0.99, "gx": 0.002, "gy": 0.001, "gz": 0.015 }
    }
  ]
}
```

| Command | Result |
|---|---|
| `Trace(gpxURL:)` | Import from GPX (location only) |
| `trace.geoJSON()` | Export as a GeoJSON `LineString` for viewing on any map |

## Architecture

```
┌──────────────┐    ┌────────┐    ┌──────────────┐    ┌───────────────────┐
│ TraceRecorder│ ─▶ │ Trace  │ ─▶ │ Perturbation │ ─▶ │ TracePlayer       │ ─▶ your navigation code
│ (CoreLocation│    │ (JSON) │    │ pipeline     │    │ (AsyncStream,     │
│ + CoreMotion)│    └────────┘    └──────────────┘    │  variable speed)  │
└──────────────┘                                      └───────────────────┘
```

- **Recorder** and **Player** are actors, so they're safe to use from any task.
- **Perturbations** are pure functions `Trace -> Trace`, which keeps them easy to compose and test.
- The public API is small and stable. Internals are `internal` or `package` scoped so they can change without breaking you.

## Sample app

`Examples/DriveEchoDemo` records a drive, shows it on a map, and replays it with live tunnel and drift toggles.

## Documentation

The full API reference is written in DocC:

```bash
swift package generate-documentation --target DriveEcho
```

## Versioning

DriveEcho follows [Semantic Versioning](https://semver.org). Breaking API changes only happen in major versions, and each one ships with migration notes in `CHANGELOG.md`.

## Roadmap

- [ ] Android / Kotlin port with a shared trace format
- [ ] CarPlay replay support
- [ ] Trace trimming and merging CLI
- [ ] Barometer and heading samples

## Contributing

Issues and pull requests are welcome. Please run `swift test` before opening a PR, and add a trace fixture for any bug you fix.

## License

MIT © Afzal Siddiqui
