// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseUtils",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FirebaseUtils",
            targets: ["FirebaseUtils"]),
        .library(
            name: "FirebaseUiUtils",
            targets: ["FirebaseUiUtils"]),
    ],
    dependencies: [
        .package(
            url:  "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "11.5.0")
        ),
        .package(
            url:  "https://github.com/firebase/FirebaseUI-iOS.git",
            .upToNextMajor(from: "15.0.0")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FirebaseUtils",
            dependencies: [
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk")
            ],
            path: "Sources/FirebaseUtils",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .defaultIsolation(MainActor.self)
            ]),
        .target(
            name: "FirebaseUiUtils",
            dependencies: [
                .product(name: "FirebaseAuthUI", package: "FirebaseUI-iOS"),
                .product(name: "FirebaseGoogleAuthUI", package: "FirebaseUI-iOS"),
                .product(name: "FirebaseOAuthUI", package: "FirebaseUI-iOS"),
                .product(name: "FirebaseEmailAuthUI", package: "FirebaseUI-iOS")
            ],
            path: "Sources/FirebaseUiUtils",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .defaultIsolation(MainActor.self)
            ]),
        .testTarget(
            name: "FirebaseUtilsTests",
            dependencies: ["FirebaseUtils"],
            path: "Tests",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]),
    ]
)
