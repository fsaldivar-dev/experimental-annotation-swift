// swift-tools-version: 6.2
import PackageDescription

// App de administración con roles: guardianes de navegación, sesión deslizante y auditoría,
// todo expresado como anotaciones apiladas sobre el coordinador.
//
//   swift run --package-path Examples/AdminApp     (macOS)
//   swift test --package-path Examples/AdminApp    (guardianes sin UI)
let package = Package(
    name: "AdminApp",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "AdminAppCore", targets: ["AdminAppCore"]),
    ],
    dependencies: [
        .package(name: "AnnotationSwift", path: "../.."),
    ],
    targets: [
        .target(
            name: "AdminAppCore",
            dependencies: [.product(name: "AnnotationSwift", package: "AnnotationSwift")]
        ),
        .executableTarget(name: "AdminApp", dependencies: ["AdminAppCore"]),
        .testTarget(name: "AdminAppCoreTests", dependencies: ["AdminAppCore"]),
    ]
)
