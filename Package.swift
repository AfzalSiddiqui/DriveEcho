// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DriveEcho",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "DriveEcho", targets: ["DriveEcho"]),
        .library(name: "DriveEchoTesting", targets: ["DriveEchoTesting"]),
    ],
    targets: [
        .target(
            name: "DriveEcho",
            path: "Sources/DriveEcho"
        ),
        .target(
            name: "DriveEchoTesting",
            dependencies: ["DriveEcho"],
            path: "Sources/DriveEchoTesting"
        ),
        .testTarget(
            name: "DriveEchoTests",
            dependencies: ["DriveEcho", "DriveEchoTesting"],
            path: "Tests/DriveEchoTests",
            resources: [
                .copy("../Fixtures"),
            ]
        ),
        .testTarget(
            name: "DriveEchoTestingTests",
            dependencies: ["DriveEcho", "DriveEchoTesting"],
            path: "Tests/DriveEchoTestingTests",
            resources: [
                .copy("../Fixtures"),
            ]
        ),
    ]
)
