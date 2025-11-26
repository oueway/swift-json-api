// swift-tools-version: 5.12
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftJsonApi",
    platforms: [.iOS("14.0"), .macOS("10.16"), .tvOS("14.0"), .visionOS("2.0")],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftJsonApi",
            targets: ["SwiftJsonApi"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftJsonApi"
        ),
        .testTarget(
            name: "SwiftJsonApiTests",
            dependencies: ["SwiftJsonApi"]
        ),
    ]
)
