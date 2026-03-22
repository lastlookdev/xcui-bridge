// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "XCUIBridge",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "XCUIBridge",
            targets: ["XCUIBridge"]
        ),
    ],
    targets: [
        .target(
            name: "ObjCExceptionCatcher",
            publicHeadersPath: "include"
        ),
        .target(
            name: "XCUIBridge",
            dependencies: ["ObjCExceptionCatcher"]
        ),
    ]
)
