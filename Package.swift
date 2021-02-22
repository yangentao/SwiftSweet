// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftSweet",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_11)
    ],
    products: [
        .library(name: "SwiftSweet", targets: ["SwiftSweet"]),
    ],
    targets: [
        .target(name: "SwiftSweet", path: "SwiftSweet/Classes/"),
        .testTarget(name:"SwiftSweetTests", dependencies:["SwiftSweet"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
