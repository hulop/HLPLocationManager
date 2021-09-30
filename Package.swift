// swift-tools-version:5.3
import PackageDescription

let version = "1.1.0-beta"

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
            url: "https://github.com/hulop/HLPLocationManager/releases/download/v1.1.0-beta/HLPLocationManager.xcframework.zip",
            checksum: "4245ab7596414f0de3ceaa9929533685e44b014ce8e6d26a80289d124537f7ec"
        )
    ]
)
