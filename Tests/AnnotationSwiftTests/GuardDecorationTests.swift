//
//  GuardDecorationTests.swift
//  AnnotationSwiftTests
//

import AnnotationSwift
import Testing

@Suite("Guardianes y decoradores que lanzan", .serialized)
struct GuardDecorationTests {

    @Test("Un guardián detiene el cuerpo y los decoradores interiores no se ejecutan")
    func guardDenies() {
        Recorder.shared.reset("guarded")
        Authorized.currentRole = "viewer"
        var admin = Admin()
        #expect(throws: AccessError.forbidden("deleteEverything()")) { try admin.deleteEverything() }
        #expect(admin.deleted == 0)
        #expect(Recorder.shared.events("guarded").isEmpty)
    }

    @Test("Un guardián deja pasar cuando la condición se cumple")
    func guardAllows() throws {
        Recorder.shared.reset("guarded")
        Authorized.currentRole = "admin"
        var admin = Admin()
        #expect(try admin.deleteEverything() == 1)
        #expect(Recorder.shared.events("guarded").count == 2)
    }

    @Test("El guardián funciona igual en funciones async")
    func guardAsync() async throws {
        Authorized.currentRole = "viewer"
        await #expect(throws: AccessError.forbidden("report()")) { try await Admin().report() }
        Authorized.currentRole = "admin"
        #expect(try await Admin().report() == "report")
    }

    @Test("Un ThrowingDecorator puede lanzar su propio error después del cuerpo")
    func timeout() async throws {
        #expect(try await Admin().slow(.milliseconds(1)) == "done")
        await #expect(throws: AccessError.timedOut) { try await Admin().slow(.milliseconds(120)) }
    }
}
