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
            dependencies: [.product(name: "AnnotationSwift", package: "AnnotationSwift")]
            // Las declaraciones de los tipos @Annotation están commiteadas en
            // Sources/Demo/AnnotationRegistry.generated.swift, generadas con:
            //   swift package --allow-writing-to-package-directory annotation-registry
            // Alternativa sin commitear nada (corre en cada build):
            //   plugins: [.plugin(name: "AnnotationRegistry", package: "AnnotationSwift")]
        ),
    ]
)
