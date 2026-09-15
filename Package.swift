// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-syntax-learn",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "swift-syntax-learn", targets: ["swift-syntax-learn"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "swift-syntax-learn",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ],
        ),
        .testTarget(
            name: "swift-syntax-learnTests",
            dependencies: ["swift-syntax-learn"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
