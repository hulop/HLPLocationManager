// swift-tools-version:5.3
import PackageDescription

let version = "1.2.0"

let package = Package(
    name: "HLPLocationManager",
    products: [
        .library(
            name: "HLPLocationManager",
            targets: ["HLPLocationManager"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "HLPLocationManager",
//            url: "https://url/to/some/remote/xcframework.zip",
//            url: "file:///Users/cabot/src/HLPLocationManager/HLPLocationManager.xcframework.zip",
//            checksum: "8d82cb08685c2f3bf2ef36a1321e49a4b19c66b81ef43309b0851f5abe64f7cf"
            path: "HLPLocationManager.xcframework"
        )
    ]
)
