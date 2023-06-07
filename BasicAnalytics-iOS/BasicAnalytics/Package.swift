// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BasicAnalytics",
    platforms: [
        .macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7)
    ], products: [
        .library(
            name: "BasicAnalytics",
            targets: ["BasicAnalytics"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BasicAnalytics",
            dependencies: []),
        .testTarget(
            name: "BasicAnalyticsTests",
            dependencies: ["BasicAnalytics"]),
    ]
)
