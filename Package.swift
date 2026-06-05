// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "sindriPDF",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "sindriPDF", targets: ["sindriPDF"])
    ],
    targets: [
        .executableTarget(
            name: "sindriPDF",
            dependencies: [],
            path: "Sources"
        )
    ]
)
