// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZegoAIAgentActionObjC",
    platforms: [.iOS(.v13), .macOS(.v12)],
    products: [
        .library(name: "ZegoAIAgentActionObjC", targets: ["ZegoAIAgentActionObjC"])
    ],
    targets: [
        .target(
            name: "ZegoAIAgentActionObjC",
            path: "Sources/ZegoAIAgentActionObjC",
            exclude: ["Generated"],
            publicHeadersPath: "include"
        )
    ]
)
