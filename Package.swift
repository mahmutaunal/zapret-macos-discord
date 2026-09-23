// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ZapretMenu",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ZapretMenu", targets: ["ZapretMenu"])
    ],
    targets: [
        .target(name: "ZapretMenuCore"),
        .executableTarget(
            name: "ZapretMenu",
            dependencies: ["ZapretMenuCore"]
        ),
        .testTarget(
            name: "ZapretMenuCoreTests",
            dependencies: ["ZapretMenuCore"]
        )
    ]
)
