//
//  ExpansionTests.swift
//  AnnotationMacrosTests
//

import AnnotationMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

/// Procesador + marcadores, como los ve un módulo cliente.
let publicMacros: [String: Macro.Type] = [
    "Decorable": DecorableMacro.self,
    "Logged": MarkerMacro.self,
    "Retry": MarkerMacro.self,
    "Trimmed": MarkerMacro.self,
    "Lowercased": MarkerMacro.self,
]

/// Solo las macros internas, para fijar su expansión aislada. Los marcadores quedan como
/// atributos sin expandir, igual que los ve la macro interna en una compilación real.
let internalMacros: [String: Macro.Type] = [
    "_DecoratedFunction": DecoratedFunctionMacro.self,
    "_DecoratedProperty": DecoratedPropertyMacro.self,
]

final class ExpansionTests: XCTestCase {

    // MARK: @Decorable adjunta las macros internas solo a los miembros con marcadores

    func testDecorableAttachesInternalMacros() {
        assertMacroExpansion(
            """
            @Decorable
            struct Service {
                @Logged
                func fetch() {}

                @Trimmed
                var email: String

                var plain: Int

                func untouched() {}
            }
            """,
            expandedSource: """
            struct Service {
                @AnnotationSwift._DecoratedFunction
                func fetch() {}
                @AnnotationSwift._DecoratedProperty
                var email: String

                var plain: Int

                func untouched() {}
            }
            """,
            macros: publicMacros
        )
    }

    // MARK: Funciones

    func testAsyncThrowingFunction() {
        assertMacroExpansion(
            """
            struct Service {
                @_DecoratedFunction
                @Logged
                @Retry(3)
                func fetch(id: Int, _ flag: Bool, onDone: () -> Void) async throws -> Int {
                    return id
                }
            }
            """,
            expandedSource: """
            struct Service {
                @Logged
                @Retry(3)
                func fetch(id: Int, _ flag: Bool, onDone: () -> Void) async throws -> Int {
                    let __annotation_call = AnnotationSwift.Call(function: "fetch(id:_:onDone:)", type: "Service", file: "TestModule/test.swift", line: 2, arguments: [AnnotationSwift.Call.Argument(name: "id", label: "id", value: id), AnnotationSwift.Call.Argument(name: "flag", label: nil, value: flag)])
                    return try await Logged().decorate(__annotation_call, isolation: #isolation) { () async throws -> Int in
                        return try await Retry(3).decorate(__annotation_call, isolation: #isolation) { () async throws -> Int in
                            return id
                        }
                    }
                }
            }
            """,
            macros: internalMacros
        )
    }

    func testSyncVoidFunction() {
        assertMacroExpansion(
            """
            struct Service {
                @_DecoratedFunction
                @Logged
                func ping() {
                    print("pong")
                }
            }
            """,
            expandedSource: """
            struct Service {
                @Logged
                func ping() {
                    let __annotation_call = AnnotationSwift.Call(function: "ping()", type: "Service", file: "TestModule/test.swift", line: 2)
                    return Logged().decorate(__annotation_call) { () -> Void in
                        print("pong")
                    }
                }
            }
            """,
            macros: internalMacros
        )
    }

    // MARK: Propiedades

    func testProperty() {
        assertMacroExpansion(
            """
            struct User {
                @_DecoratedProperty
                @Trimmed
                @Lowercased
                var email: String = "X"
            }
            """,
            expandedSource: """
            struct User {
                @Trimmed
                @Lowercased
                var email: String {
                    @storageRestrictions(initializes: _email)
                    init(initialValue) {
                        let __annotation_property = AnnotationSwift.Property(name: "email", type: "User", file: "TestModule/test.swift", line: 2)
                        _email = Trimmed().decorate(initialValue, __annotation_property) { __v in
                            Lowercased().decorate(__v, __annotation_property) { __v in
                                __v
                            }
                        }
                    }
                    get {
                        _email
                    }
                    set {
                        let __annotation_property = AnnotationSwift.Property(name: "email", type: "User", file: "TestModule/test.swift", line: 2)
                        _email = Trimmed().decorate(newValue, __annotation_property) { __v in
                            Lowercased().decorate(__v, __annotation_property) { __v in
                                __v
                            }
                        }
                    }
                }

                private var _email: String = "X"
            }
            """,
            macros: internalMacros
        )
    }

    // MARK: Diagnósticos

    func testMarkerWithoutDecorable() {
        assertMacroExpansion(
            """
            struct Service {
                @Logged
                func fetch() {}
            }
            """,
            expandedSource: """
            struct Service {
                func fetch() {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "'@Logged' has no effect: add @Decorable to 'Service'", line: 2, column: 5),
            ],
            macros: publicMacros
        )
    }

    func testMarkerAtTopLevel() {
        assertMacroExpansion(
            """
            @Logged
            func fetch() {}
            """,
            expandedSource: """
            func fetch() {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "'@Logged' has no effect here: decorators can only be applied to members of a @Decorable type", line: 1, column: 1),
            ],
            macros: publicMacros
        )
    }

    func testMarkerInsideProtocolIsInert() {
        assertMacroExpansion(
            """
            protocol LoginRepository {
                @Logged
                @Retry(2)
                func getLogin() async throws -> String
            }
            """,
            expandedSource: """
            protocol LoginRepository {
                func getLogin() async throws -> String
            }
            """,
            diagnostics: [],
            macros: publicMacros
        )
    }

    func testDecorableOnProtocolIsRejected() {
        assertMacroExpansion(
            """
            @Decorable
            protocol LoginRepository {
                @Logged
                func getLogin() async throws -> String
            }
            """,
            expandedSource: """
            protocol LoginRepository {
                func getLogin() async throws -> String
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Decorable cannot be applied to a protocol: requirements have no body to wrap; apply it to the conforming type", line: 3, column: 5),
            ],
            macros: publicMacros
        )
    }

    func testUnsupportedMembers() {
        assertMacroExpansion(
            """
            @Decorable
            struct Service {
                @Trimmed
                let name: String

                @Trimmed
                static var shared = ""

                @Trimmed
                var computed: String { "" }

                @Logged
                init() {}
            }
            """,
            expandedSource: """
            struct Service {
                let name: String
                static var shared = ""
                var computed: String { "" }
                init() {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "decorators cannot be applied to a 'let' constant; use 'var'", line: 4, column: 5),
                DiagnosticSpec(message: "decorators cannot be applied to a 'static' property", line: 7, column: 5),
                DiagnosticSpec(message: "decorators can only be applied to stored properties", line: 10, column: 9),
                DiagnosticSpec(message: "decorators can only be applied to functions and stored properties", line: 12, column: 5),
            ],
            macros: publicMacros
        )
    }

    func testPropertyInExtensionAndTypedThrows() {
        assertMacroExpansion(
            """
            @Decorable
            extension Service {
                @Trimmed
                var name: String

                @_DecoratedFunction
                @Logged
                func fetch() throws(Boom) {}
            }
            """,
            expandedSource: """
            extension Service {
                var name: String
                @AnnotationSwift._DecoratedFunction
                func fetch() throws(Boom) {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "decorators cannot be applied to properties declared in an extension", line: 3, column: 5),
                DiagnosticSpec(message: "decorators do not support typed throws; declare the function as 'throws'", line: 9, column: 25),
            ],
            macros: publicMacros.merging(internalMacros) { a, _ in a }
        )
    }
}
