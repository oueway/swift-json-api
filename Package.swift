// swift-tools-version: 5.12
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftJsonApi",
    platforms: [.iOS("14.0"), .macOS("10.16"), .tvOS("14.0"), .visionOS("2.0")],
    products: [
        .library(name: "SwiftCommon", targets: ["SwiftCommon"]),
        .library(name: "SwiftJsonApi", targets: ["SwiftJsonApi"]),
    ],
    targets: [
        .target(name: "SwiftCommon"),
        .target(name: "SwiftJsonApi", dependencies: ["SwiftCommon"]),
        .executableTarget(name: "ExampleApp", dependencies: ["SwiftJsonApi"]),
        .testTarget(
            name: "SwiftJsonApiTests",
            dependencies: ["SwiftJsonApi"]
        ),
    ]
)
