// swift-tools-version:5.3
import PackageDescription

let version = "1.1.0-epsilon"

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
            url: "https://github.com/hulop/HLPLocationManager/releases/download/v1.1.0-epsilon/HLPLocationManager.xcframework.zip",
            checksum: "806c02c80ae0712407d8925b0d4761e834f02e6f3886a9f4309120441e19560d"
        )
    ]
)
