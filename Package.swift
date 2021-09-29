// swift-tools-version:5.3
import PackageDescription

let version = "1.1.0-alpha"

let package = Package(
    name: "HLPLocationManager",
    products: [
        .library(
            name: "HLPLocationManager",
            targets: ["HLPLocationManager"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/hulop/blelocpp.git",
            .exact("1.4.0-alpha")
        ),
        .package(
            url: "https://github.com/ZipArchive/ZipArchive.git",
            .exact("2.4.2")
        )
    ],
    targets: [
        .binaryTarget(
            name: "HLPLocationManager",
            url: "https://github.com/hulop/HLPLocationManager/releases/download/v1.1.0-alpha/HLPLocationManager.xcframework.zip",
            checksum: "45622ae3389ec84d735436a3076284668889faeb96a532a88197438530c8f916"
        )
    ]
)
