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
        .package(url: "https://github.com/nicklama/IGListKit-spm.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "IOSChatView",
            dependencies: [
                .product(name: "IGListKit", package: "IGListKit-spm"),
            ],
            path: "Sources/IOSChatView"
        ),
    ]
)
