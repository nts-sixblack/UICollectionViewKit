// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UICollectionViewKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "UICollectionViewKit", targets: ["UICollectionViewKit"]),
    ],
    targets: [
        .target(name: "UICollectionViewKit"),
        .testTarget(
            name: "UICollectionViewKitTests",
            dependencies: ["UICollectionViewKit"]
        ),
    ]
)
