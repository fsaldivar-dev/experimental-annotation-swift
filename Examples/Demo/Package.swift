// swift-tools-version: 6.0
import PackageDescription

// Paquete cliente: depende de AnnotationSwift como lo haría cualquier app y define sus
// propios decoradores. Sirve de ejemplo y de prueba de integración.
let package = Package(
    name: "Demo",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(name: "AnnotationSwift", path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "Demo",
            dependencies: [.product(name: "AnnotationSwift", package: "AnnotationSwift")]
        ),
    ]
)
