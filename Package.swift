// swift-tools-version:5.3
import PackageDescription

let version = "1.1.0-delta"

let package = Package(
    name: "HLPLocationManager",
    products: [
        .library(
            name: "HLPLocationManager",
            targets: ["HLPLocationManager"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/hulop/blelocpp",
            .exact("1.4.0-alpha")
        ),
        .package(
            url: "https://github.com/AndrewSB/ZipArchive",
            .revision("a6ef3c6c3b3dc30a69936ccd68cbfd3946024818")
        )
    ],
    targets: [
        .binaryTarget(
            name: "HLPLocationManager",
            url: "https://github.com/hulop/HLPLocationManager/releases/download/v1.1.0-delta/HLPLocationManager.xcframework.zip",
            checksum: "9476ee2d2d3e0dc9a2e4abde147cd26d78ea0bfe9169ee2e71d8a9d0d51fe904"
        )
    ]
)
