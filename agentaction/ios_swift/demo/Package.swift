// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZegoAIAgentActionDemo",
    platforms: [.iOS(.v13), .macOS(.v12)],
    dependencies: [
        .package(path: "../agentaction"),
        .package(url: "https://github.com/zegoim/zego-express-video-ios.git", from: "3.15.0")
    ],
    targets: [
        .executableTarget(
            name: "ZegoAIAgentActionDemo",
            dependencies: [
                .product(name: "ZegoAIAgentAction", package: "agentaction"),
                .product(name: "ZegoExpressEngine", package: "zego-express-video-ios")
            ]
        )
    ]
)
