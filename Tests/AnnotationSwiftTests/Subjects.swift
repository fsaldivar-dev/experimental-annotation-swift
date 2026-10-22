//
//  Subjects.swift
//  AnnotationSwiftTests
//
//  Tipos decorados que ejercitan las distintas formas de función y propiedad.
//

import AnnotationSwift
import Foundation

struct Boom: Error, Equatable {}

@Decorable
struct Service {
    var attempts = 0

    @Logged(into: "hello")
    func hello(name: String) -> String { "hola \(name)" }

    @Logged(into: "flaky")
    @Retry(3)
    mutating func flaky(failures: Int) async throws -> Int {
        attempts += 1
        if attempts <= failures { throw Boom() }
        return attempts
    }

    @Retry(2)
    mutating func flakySync(failures: Int) throws -> Int {
        attempts += 1
        if attempts <= failures { throw Boom() }
        return attempts
    }

    @Logged(into: "fail")
    func fail() throws { throw Boom() }

    @Logged(into: "args")
    func sum(_ a: Int, b: Int, using transform: (Int) -> Int) -> Int { transform(a + b) }

    @Logged(into: "static")
    static func version() -> String { "1.0.0" }

    @Logged(into: "generic")
    func identity<T>(_ value: T) -> T { value }

    @Logged(into: "inout")
    func bump(_ value: inout Int) { value += 1 }

    @discardableResult
    @Logged(into: "discardable")
    func discardable() -> Int { 42 }

    @Logged(into: "opaque")
    func numbers() -> some Sequence<Int> { [1, 2, 3] }

    @Logged(into: "guard")
    func early(_ flag: Bool) -> String {
        guard flag else { return "early" }
        defer { _ = flag }
        return "late"
    }
}

@Decorable
extension Service {
    @Logged(into: "extension")
    func fromExtension() -> Int { attempts }
}

@Decorable
@MainActor
final class ViewModel {
    var title = ""

    @Logged(into: "main")
    func load() async {
        MainActor.assertIsolated()
        await Task.yield()
        title = "ok"
    }
}

@Decorable
actor Counter {
    var count = 0

    @Logged(into: "actor")
    func increment() -> Int {
        count += 1
        return count
    }
}

@Decorable
struct User {
    @Trimmed
    @Lowercased
    var email: String = "  PACO@Mail.com  "

    @Clamped(0...100)
    var progress: Int = 150

    @Email
    var contact: String?

    @Lowercased
    @Trimmed
    var reversedOrder: String = "  ABC  "
}

@Decorable
final class Settings {
    @Clamped(0.0...1.0)
    var volume: Double

    init(volume: Double) {
        self.volume = volume
    }
}

@Decorable
struct Admin {
    var deleted = 0

    @Authorized("admin")
    @Logged(into: "guarded")
    mutating func deleteEverything() throws -> Int {
        deleted += 1
        return deleted
    }

    @Authorized("admin")
    func report() async throws -> String { "report" }

    @Timeout(.milliseconds(50))
    func slow(_ sleep: Duration) async throws -> String {
        try await Task.sleep(for: sleep)
        return "done"
    }
}

/// La forma sin marcadores declarados: los decoradores van como valores.
@Decorable
struct Inline {
    var attempts = 0

    @Decorate(Logged(into: "inline"), Retry(3))
    mutating func flaky() async throws -> Int {
        attempts += 1
        if attempts < 3 { throw Boom() }
        return attempts
    }

    /// Mezcla: @Decorate y un marcador clásico, en orden de escritura → Logged, Retry, Authorized.
    @Decorate(Logged(into: "mixed"))
    @Authorized("admin")
    func secret() throws -> String { "s3cr3t" }

    @Decorate(Trimmed(), Lowercased())
    var email: String = "  PACO@Mail.com "

    @Decorate(Lowercased())
    @Trimmed
    var tag: String = "  X  "
}
