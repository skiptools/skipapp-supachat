// swift-tools-version: 5.9
// This is a Skip (https://skip.tools) package,
// containing a Swift Package Manager project
// that will use the Skip build plugin to transpile the
// Swift Package, Sources, and Tests into an
// Android Gradle Project with Kotlin sources and JUnit tests.
import PackageDescription

let package = Package(
    name: "skipapp-supatodo",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SupaTODOApp", type: .dynamic, targets: ["SupaTODO"]),
        .library(name: "SupaTODOModel", type: .dynamic, targets: ["SupaTODOModel"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.10.6"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "0.11.2"),
        .package(url: "https://source.skip.tools/skip-kit.git", from: "0.0.1"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.7.0"),
        .package(url: "https://source.skip.tools/skip-model.git", from: "0.8.0"),
        .package(url: "https://source.skip.tools/skip-supabase.git", from: "0.0.1")
    ],
    targets: [
        .target(name: "SupaTODO", dependencies: [
            "SupaTODOModel",
            .product(name: "SkipUI", package: "skip-ui"),
            .product(name: "SkipKit", package: "skip-kit")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SupaTODOTests", dependencies: [
            "SupaTODO",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SupaTODOModel", dependencies: [
            .product(name: "SkipFoundation", package: "skip-foundation"),
            .product(name: "SkipModel", package: "skip-model"),
            .product(name: "SkipSupabase", package: "skip-supabase")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SupaTODOModelTests", dependencies: [
            "SupaTODOModel",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
