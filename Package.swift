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
        .target(name: "SwiftSweet", path: "SwiftSweet/Classes/")
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
