// swift-tools-version: 6.2
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
            dependencies: [.product(name: "AnnotationSwift", package: "AnnotationSwift")],
            // Genera las declaraciones de marcador de los tipos @Annotation antes de compilar.
            plugins: [.plugin(name: "AnnotationRegistry", package: "AnnotationSwift")]
        ),
    ]
)
