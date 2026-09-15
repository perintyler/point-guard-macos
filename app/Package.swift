// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PointGuard",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "PointGuard", targets: ["PointGuard"])
    ],
    dependencies: [
        // BarryKit is declared for consistency with the other bag apps (and so
        // the product table in its README can eventually list this one), but
        // its transport is not used here — see PointGuardClient's doc comment
        // for why point-guard talks to its own service with its own
        // discovery instead of BarryCore's launchd-plist lookup.
        .package(path: "../../../barry/packages/BarryKit")
    ],
    targets: [
        // Pure, UI- and network-independent logic: models, status mapping,
        // relative-time formatting and row view-model construction. No
        // AppKit/SwiftUI/URLSession imports here, so it is testable without a
        // window or a live service — the same split ActionsFeature and
        // BarrySessionsCore use.
        .target(
            name: "PointGuardCore",
            path: "PointGuardCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "PointGuardCoreTests",
            dependencies: ["PointGuardCore"],
            path: "PointGuardCoreTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "PointGuard",
            dependencies: [
                "PointGuardCore",
                .product(name: "BarryKit", package: "BarryKit")
            ],
            path: "Sources/App",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // The book-JSON contract-decode test lives at the app level, mirroring
        // sessions-macos's Tests/ContractDecodeTests.swift location, so
        // PointGuardCoreTests can stay focused on logic given already-decoded
        // models.
        .testTarget(
            name: "PointGuardTests",
            dependencies: ["PointGuardCore"],
            path: "Tests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
