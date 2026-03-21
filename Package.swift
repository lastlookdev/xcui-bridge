// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LastLookBridge",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "LastLookBridge",
            targets: ["LastLookBridge"]
        ),
    ],
    targets: [
        .target(
            name: "LastLookBridge",
            linkerSettings: [
                .linkedFramework("XCTest"),
            ]
        ),
    ]
)
