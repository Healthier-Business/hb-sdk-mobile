// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HbEmbed",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "HbEmbed", targets: ["HbEmbed"]),
    ],
    targets: [
        .target(name: "HbEmbed"),
    ]
)
