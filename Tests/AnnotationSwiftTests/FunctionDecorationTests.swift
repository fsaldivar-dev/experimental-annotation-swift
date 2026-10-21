//
//  FunctionDecorationTests.swift
//  AnnotationSwiftTests
//

import AnnotationSwift
import Testing

@Suite("Decoradores de función", .serialized)
struct FunctionDecorationTests {

    @Test("Una función síncrona se envuelve y devuelve su valor")
    func sync() {
        Recorder.shared.reset("hello")
        #expect(Service().hello(name: "Paco") == "hola Paco")
        #expect(Recorder.shared.events("hello") == ["→ hello(name:)", "← hello(name:) = hola Paco"])
    }

    @Test("Logged por fuera de Retry: un solo par de eventos para tres intentos")
    func loggedOutsideRetry() async throws {
        Recorder.shared.reset("flaky")
        var service = Service()
        let result = try await service.flaky(failures: 2)
        #expect(result == 3)
        #expect(service.attempts == 3)
        #expect(Recorder.shared.events("flaky") == ["→ flaky(failures:)", "← flaky(failures:) = 3"])
    }

    @Test("Retry propaga el último error cuando se agotan los intentos")
    func retryExhausted() async {
        var service = Service()
        await #expect(throws: Boom.self) { try await service.flaky(failures: 10) }
        #expect(service.attempts == 3)
    }

    @Test("Retry también funciona en funciones síncronas")
    func retrySync() throws {
        var service = Service()
        #expect(try service.flakySync(failures: 1) == 2)
        service.attempts = 0
        #expect(throws: Boom.self) { try service.flakySync(failures: 5) }
        #expect(service.attempts == 2)
    }

    @Test("El error de la función llega al decorador y se propaga")
    func throwing() {
        Recorder.shared.reset("fail")
        #expect(throws: Boom.self) { try Service().fail() }
        #expect(Recorder.shared.events("fail") == ["→ fail()", "✗ fail(): Boom()"])
    }

    @Test("Call lleva el nombre completo, el tipo, la ubicación y los argumentos")
    func callMetadata() {
        Recorder.shared.reset("args")
        #expect(Service().sum(1, b: 2) { $0 * 10 } == 30)
        let call = try! #require(Recorder.shared.calls("args").first)
        #expect(call.function == "sum(_:b:using:)")
        #expect(call.type == "Service")
        #expect(call.description == "Service.sum(_:b:using:)")
        #expect(call.file.hasSuffix("Subjects.swift"))
        #expect(call.line > 0)
        // El closure no escapante se omite de los argumentos.
        #expect(call.arguments.map(\.description) == ["a: 1", "b: 2"])
        #expect(call.arguments.map(\.label) == [nil, "b"])
    }

    @Test("Funciones estáticas, genéricas, con inout, discardableResult y retorno opaco")
    func otherShapes() {
        Recorder.shared.reset("static"); Recorder.shared.reset("generic")
        Recorder.shared.reset("inout"); Recorder.shared.reset("discardable"); Recorder.shared.reset("opaque")

        #expect(Service.version() == "1.0.0")
        #expect(Recorder.shared.calls("static").first?.type == "Service")

        #expect(Service().identity("x") == "x")
        #expect(Recorder.shared.events("generic").last == "← identity(_:) = x")

        var n = 1
        Service().bump(&n)
        #expect(n == 2)
        #expect(Recorder.shared.calls("inout").first?.arguments.first?.description == "value: 1")

        Service().discardable()
        #expect(Recorder.shared.events("discardable").count == 2)

        #expect(Array(Service().numbers()) == [1, 2, 3])
        #expect(Recorder.shared.events("opaque").count == 2)
    }

    @Test("guard, defer y return anticipado conservan su semántica dentro del cuerpo envuelto")
    func controlFlow() {
        #expect(Service().early(false) == "early")
        #expect(Service().early(true) == "late")
    }

    @Test("@Decorable también funciona en una extensión")
    func extensionMembers() {
        Recorder.shared.reset("extension")
        #expect(Service().fromExtension() == 0)
        #expect(Recorder.shared.events("extension").count == 2)
    }

    @Test("Una clase @MainActor conserva su aislamiento dentro del decorador")
    @MainActor
    func mainActor() async {
        Recorder.shared.reset("main")
        let viewModel = ViewModel()
        await viewModel.load()
        #expect(viewModel.title == "ok")
        #expect(Recorder.shared.events("main") == ["→ load()", "← load() = ()"])
    }

    @Test("Un método de actor se decora como función síncrona dentro del actor")
    func actorMethod() async {
        Recorder.shared.reset("actor")
        let counter = Counter()
        #expect(await counter.increment() == 1)
        #expect(await counter.increment() == 2)
        #expect(Recorder.shared.calls("actor").first?.type == "Counter")
    }
}
