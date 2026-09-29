import XCTest
import Foundation

/// Assert that a reroute occurred within the given tolerance after the driver left the route.
public func XCTAssertRerouted(
    _ result: RunResult,
    within tolerance: Duration,
    afterLeavingRouteAt expectedOffRouteTime: Duration,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let toleranceSeconds = tolerance.driveEchoTimeInterval

    guard let offRoute = result.events.first(where: {
        if case .offRoute = $0 { return true }
        return false
    }) else {
        XCTFail("Expected off-route event but none occurred", file: file, line: line)
        return
    }

    guard let reroute = result.events.first(where: {
        if case .rerouted = $0 { return true }
        return false
    }) else {
        XCTFail("Expected reroute event but none occurred", file: file, line: line)
        return
    }

    if case .offRoute(let actualOffRoute) = offRoute,
       case .rerouted(let actualReroute) = reroute
    {
        let delay = actualReroute - actualOffRoute
        XCTAssertLessThanOrEqual(
            delay, toleranceSeconds,
            "Reroute took \(delay)s after off-route, expected within \(toleranceSeconds)s",
            file: file, line: line
        )
    }
}

/// Assert that the navigator stayed on route for the entire trace.
public func XCTAssertStaysOnRoute(
    _ result: RunResult,
    toleranceMeters: Double = 50,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let offRouteEvents = result.events.filter {
        if case .offRoute = $0 { return true }
        return false
    }
    XCTAssertTrue(
        offRouteEvents.isEmpty,
        "Expected to stay on route but got \(offRouteEvents.count) off-route event(s)",
        file: file,
        line: line
    )
}

// MARK: - Duration helper (package-internal to avoid conflict with DriveEcho target)

extension Duration {
    var driveEchoTimeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
}
