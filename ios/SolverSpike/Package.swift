// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SolverSpike",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "SolverSpikeCore", targets: ["SolverSpikeCore"]),
        .executable(name: "SolverSpike", targets: ["SolverSpike"])
    ],
    targets: [
        .target(name: "SolverSpikeCore"),
        .executableTarget(
            name: "SolverSpike",
            dependencies: ["SolverSpikeCore"]
        ),
        .testTarget(
            name: "SolverSpikeCoreTests",
            dependencies: ["SolverSpikeCore"]
        )
    ]
)

