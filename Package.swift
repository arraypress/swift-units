// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Units",
    platforms: [
        .macOS(.v14), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1),
    ],
    products: [
        .library(name: "Units", targets: ["Units"]),
    ],
    targets: [
        .target(name: "Units"),
        .testTarget(name: "UnitsTests", dependencies: ["Units"]),
    ]
)
