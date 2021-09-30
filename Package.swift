// swift-tools-version:5.3
import PackageDescription

let version = "1.1.0-gamma"

let package = Package(
    name: "HLPLocationManager",
    products: [
        .library(
            name: "HLPLocationManager",
            targets: ["HLPLocationManager"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/ZipArchive/ZipArchive.git",
            .exact("2.4.2")
        )
    ],
    targets: [
        .binaryTarget(
            name: "HLPLocationManager",
            url: "https://github.com/hulop/HLPLocationManager/releases/download/v1.1.0-gamma/HLPLocationManager.xcframework.zip",
            checksum: "f8c8fa65f79771ec60aaa739ede500daf00cacbe6333c5cf23fba5d2cc4b8b3c"
        )
    ]
)
