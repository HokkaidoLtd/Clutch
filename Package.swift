// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Clutch",
    platforms: [.iOS(.v12)],
    dependencies: [
        .package(name: "PrivateMobileCoreServices", path: "PrivateMobileCoreServices"),
        .package(name: "ASLRDisabler", path: "ASLRDisabler"),
        .package(name: "FrameworkDumper", path: "FrameworkDumper"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "Clutch",
            dependencies: [
                .product(name: "ASLRDisabler", package: "ASLRDisabler"),
                .product(name: "FrameworkDumper", package: "FrameworkDumper"),
                .product(name: "PrivateMobileCoreServices", package: "PrivateMobileCoreServices"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
