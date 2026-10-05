// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MossTextEditor",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "MossTextEditor",
            targets: ["MossTextEditor"]
        ),
    ],
    targets: [
        .target(name: "MossTextEditor"),
        .testTarget(
            name: "MossTextEditorTests",
            dependencies: ["MossTextEditor"]
        ),
    ]
)
