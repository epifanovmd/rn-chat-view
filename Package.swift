// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "IOSChatView",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "IOSChatView",
            targets: ["IOSChatView"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ra1028/DifferenceKit.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "IOSChatView",
            dependencies: ["DifferenceKit"],
            path: "Sources/IOSChatView"
        ),
    ]
)
