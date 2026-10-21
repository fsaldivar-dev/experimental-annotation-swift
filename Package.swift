// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AnnotationSwift",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13), .visionOS(.v1),
    ],
    products: [
        /// Runtime (`Decorator`, `PropertyDecorator`, `Call`, `Property`) y las macros `@Decorable` y marcadores.
        .library(name: "AnnotationSwift", targets: ["AnnotationSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
    ],
    targets: [
        // Plugin del compilador: un único procesador genérico para todas las anotaciones.
        .macro(
            name: "AnnotationMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
        // Runtime público.
        .target(name: "AnnotationSwift", dependencies: ["AnnotationMacros"]),

        // Pruebas end-to-end: decoradores reales apilados sobre funciones y propiedades.
        .testTarget(name: "AnnotationSwiftTests", dependencies: ["AnnotationSwift"]),
        // Pruebas de expansión y diagnósticos de las macros.
        .testTarget(
            name: "AnnotationMacrosTests",
            dependencies: [
                "AnnotationMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
