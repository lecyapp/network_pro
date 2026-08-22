// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "network_pro",
    platforms: [
        // NWPathMonitor is instantiated unconditionally in NetworkProPlugin, and
        // it is iOS 12+. The podspec previously claimed 11.0, which never held.
        .iOS("12.0")
    ],
    products: [
        .library(name: "network-pro", targets: ["network_pro"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "network_pro",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
