//
//  DecorateFormTests.swift
//  AnnotationSwiftTests
//

import AnnotationSwift
import Testing

@Suite("@Decorate(…): decoradores como valores", .serialized)
struct DecorateFormTests {

    @Test("Función: la lista se encadena en orden y envuelve el cuerpo")
    func function() async throws {
        Recorder.shared.reset("inline")
        var inline = Inline()
        #expect(try await inline.flaky() == 3)
        #expect(Recorder.shared.events("inline") == ["→ flaky()", "← flaky() = 3"])   // Logged fuera de Retry
    }

    @Test("Mezcla con marcadores: orden de escritura")
    func mixed() throws {
        Recorder.shared.reset("mixed")
        Authorized.currentRole = "viewer"
        #expect(throws: AccessError.forbidden("secret()")) { try Inline().secret() }
        #expect(Recorder.shared.events("mixed") == ["→ secret()", "✗ secret(): forbidden(\"secret()\")"])  // Logged vio el rechazo
        Authorized.currentRole = "admin"
        #expect(try Inline().secret() == "s3cr3t")
    }

    @Test("Propiedad: valor por defecto y asignación pasan por la lista")
    func property() {
        var inline = Inline()
        #expect(inline.email == "paco@mail.com")
        inline.email = " OTRO@X.IO "
        #expect(inline.email == "otro@x.io")
        #expect(inline.tag == "x")          // Lowercased (de @Decorate) → Trimmed (marcador)
    }
}
