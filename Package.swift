// swift-tools-version: 5.9
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
    ],
    dependencies: [
        .package(
            url:  "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "10.0.0")
        ),
        .package(
//            url:  "git@github.com:msbahng/LoggeriOS.git",
//            .upToNextMajor(from: "1.0.0")
            path: "../LoggeriOS"
        ),
        .package(
            url: "git@github.com:msbahng/CommonUtils.git",
            branch: "develop"
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
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
                .product(name: "Logger", package: "LoggeriOS"),
                .product(name: "CommonUtils", package: "CommonUtils")
            ]),
        .testTarget(
            name: "FirebaseUtilsTests",
            dependencies: ["FirebaseUtils"]),
    ]
)
