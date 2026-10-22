import Foundation
import AnnotationRegistryCore
import Testing

@Suite("Generador de declaraciones de marcador")
struct RegistryGeneratorTests {

    func generate(_ source: String) -> String {
        RegistryGenerator().generate(sources: [("Test.swift", source)])
    }

    @Test("Sin init: macro sin parámetros")
    func noInit() {
        let output = generate("""
        @Annotation
        struct Logged: HookDecorator {
            func willCall(_ call: Call) {}
        }
        """)
        #expect(output.contains(#"@attached(peer) macro Logged() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")"#))
    }

    @Test("init explícito: copia la firma; public se respeta")
    func explicitInit() {
        let output = generate("""
        @Annotation
        public struct Retry: Decorator {
            let attempts: Int
            public init(_ attempts: Int) { self.attempts = attempts }
        }
        """)
        #expect(output.contains("@attached(peer) public macro Retry(_ attempts: Int) = #externalMacro"))
    }

    @Test("Varios init: una macro por cada uno; los privados se omiten")
    func overloads() {
        let output = generate("""
        @Annotation
        struct Logged: HookDecorator {
            init() {}
            init(into key: String) {}
            private init(secret: Int) {}
        }
        """)
        #expect(output.contains("macro Logged() ="))
        #expect(output.contains("macro Logged(into key: String) ="))
        #expect(!output.contains("secret"))
    }

    @Test("Genéricos y cláusula where")
    func generics() {
        let output = generate("""
        @Annotation
        struct Clamped<Value: Comparable>: PropertyDecorator where Value: Sendable {
            let range: ClosedRange<Value>
            init(_ range: ClosedRange<Value>) { self.range = range }
        }
        """)
        #expect(output.contains("macro Clamped<Value: Comparable>(_ range: ClosedRange<Value>) where Value: Sendable = #externalMacro"))
    }

    @Test("Memberwise: propiedades almacenadas, con sus defaults; las let con valor no entran")
    func memberwise() {
        let output = generate("""
        @Annotation
        struct Timeout: ThrowingDecorator {
            var seconds: Int = 5
            let label: String
            let fixed = 1
            static let shared = 0
            var computed: Int { 1 }
        }
        """)
        #expect(output.contains("macro Timeout(seconds: Int = 5, label: String) ="))
    }

    @Test("Tipos sin @Annotation se ignoran; sin ninguno, el archivo lo dice")
    func ignored() {
        let output = generate("struct Plain: Decorator {}")
        #expect(output.contains("ningún tipo @Annotation"))
        #expect(!output.contains("macro Plain"))
    }

    @Test("Varios archivos se acumulan en orden")
    func multipleFiles() {
        let output = RegistryGenerator().generate(sources: [
            ("A.swift", "@Annotation struct A: Decorator {}"),
            ("B.swift", "@Annotation enum B: Decorator {}"),
        ])
        let a = output.range(of: "macro A()")!.lowerBound
        let b = output.range(of: "macro B()")!.lowerBound
        #expect(a < b)
    }
}
