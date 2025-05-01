// swift-tools-version: 6.0
// This is a Skip (https://skip.tools) package.
import PackageDescription

let package = Package(
    name: "skipapp-supachat",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .macCatalyst(.v17)],
    products: [
        .library(name: "Supachat", type: .dynamic, targets: ["Supachat"]),
        .library(name: "SupachatModel", type: .dynamic, targets: ["SupachatModel"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.5.6"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", "0.0.0"..<"2.0.0"),
        .package(url: "https://github.com/skiptools/skip-keychain.git", "0.0.0"..<"2.0.0"),
        .package(url: "https://github.com/skiptools/skip-fuse.git", from: "1.0.0"),
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.26.1")
    ],
    targets: [
        .target(name: "Supachat", dependencies: [
            "SupachatModel",
            .product(name: "SkipFuseUI", package: "skip-fuse-ui")
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SupachatModel", dependencies: [
            .product(name: "SkipKeychain", package: "skip-keychain"),
            .product(name: "SkipFuse", package: "skip-fuse"),
            .product(name: "Supabase", package: "supabase-swift")
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
