// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrainYourBrain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TrainYourBrainCore",
            targets: ["TrainYourBrainCore"]
        )
    ],
    targets: [
        .target(
            name: "TrainYourBrainCore",
            path: "src",
            exclude: ["Tests", "App/TrainYourBrainApp.swift"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "TrainYourBrainCoreTests",
            dependencies: ["TrainYourBrainCore"],
            path: "src/Tests"
        )
    ]
)
