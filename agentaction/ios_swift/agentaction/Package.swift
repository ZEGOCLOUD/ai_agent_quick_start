// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZegoAIAgentAction",
    platforms: [.iOS(.v13), .macOS(.v12)],
    products: [
        .library(name: "ZegoAIAgentAction", targets: ["ZegoAIAgentAction"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.38.0")
    ],
    targets: [
        .target(
            name: "ZegoAIAgentAction",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]
        )
    ]
)
