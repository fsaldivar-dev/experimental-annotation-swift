//
//  Decorators.swift
//  AnnotationSwiftTests
//
//  Decoradores de ejemplo. Cada uno es un tipo normal más una línea que lo registra como anotación.
//

import AnnotationSwift
import Foundation

// MARK: - Registro de anotaciones (una línea por decorador)

@attached(peer) macro Logged(into key: String) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Retry(_ attempts: Int) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Trimmed() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Lowercased() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Clamped<Bound: Comparable>(_ range: ClosedRange<Bound>) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Email() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")

// MARK: - Grabadora compartida para observar qué hicieron los decoradores

final class Recorder: @unchecked Sendable {
    static let shared = Recorder()
    private let lock = NSLock()
    private var events: [String: [String]] = [:]
    private var calls: [String: [Call]] = [:]

    func record(_ event: String, call: Call, into key: String) {
        lock.lock(); defer { lock.unlock() }
        events[key, default: []].append(event)
        calls[key, default: []].append(call)
    }
    func events(_ key: String) -> [String] { lock.lock(); defer { lock.unlock() }; return events[key] ?? [] }
    func calls(_ key: String) -> [Call] { lock.lock(); defer { lock.unlock() }; return calls[key] ?? [] }
    func reset(_ key: String) { lock.lock(); defer { lock.unlock() }; events[key] = nil; calls[key] = nil }
}

// MARK: - Decoradores de función

/// Observa la llamada. Solo implementa los ganchos; `HookDecorator` provee sync y async.
struct Logged: HookDecorator {
    let key: String
    init(into key: String) { self.key = key }

    func willCall(_ call: Call) { Recorder.shared.record("→ \(call.function)", call: call, into: key) }
    func didReturn(_ call: Call, result: Any) { Recorder.shared.record("← \(call.function) = \(result)", call: call, into: key) }
    func didThrow(_ call: Call, error: any Error) { Recorder.shared.record("✗ \(call.function): \(error)", call: call, into: key) }
}

/// Controla la continuación: la ejecuta hasta `attempts` veces.
struct Retry: Decorator {
    let attempts: Int
    init(_ attempts: Int) { self.attempts = attempts }

    func decorate<Out>(_ call: Call, _ next: () throws -> Out) rethrows -> Out {
        for _ in 1..<attempts {
            if let out = try? next() { return out }
        }
        return try next()
    }

    func decorate<Out>(_ call: Call, isolation: isolated (any Actor)?, _ next: () async throws -> Out) async rethrows -> Out {
        for _ in 1..<attempts {
            if let out = try? await next() { return out }
        }
        return try await next()
    }
}

// MARK: - Decoradores de propiedad

struct Trimmed: PropertyDecorator {
    func decorate(_ value: String, _ property: Property, next: (String) -> String) -> String {
        next(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct Lowercased: PropertyDecorator {
    func decorate(_ value: String, _ property: Property, next: (String) -> String) -> String {
        next(value.lowercased())
    }
}

/// Decorador genérico: sirve para cualquier `Comparable`.
struct Clamped<Value: Comparable>: PropertyDecorator {
    let range: ClosedRange<Value>
    init(_ range: ClosedRange<Value>) { self.range = range }

    func decorate(_ value: Value, _ property: Property, next: (Value) -> Value) -> Value {
        next(min(max(value, range.lowerBound), range.upperBound))
    }
}

/// Validación al estilo de la versión original: un valor inválido se convierte en `nil`.
struct Email: PropertyDecorator {
    func decorate(_ value: String?, _ property: Property, next: (String?) -> String?) -> String? {
        guard let value, value.wholeMatch(of: /[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}/) != nil else {
            return next(nil)
        }
        return next(value)
    }
}

// MARK: - Decoradores que lanzan por su cuenta

@attached(peer) macro Authorized(_ role: String) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Timeout(_ duration: Duration) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")

enum AccessError: Error, Equatable { case forbidden(String), timedOut }

/// Guardián: una sola función `check`.
struct Authorized: GuardDecorator {
    nonisolated(unsafe) static var currentRole = "viewer"
    let role: String
    init(_ role: String) { self.role = role }

    func check(_ call: Call) throws {
        guard Self.currentRole == role else { throw AccessError.forbidden(call.function) }
    }
}

/// Lanza por su cuenta después de la continuación: necesita `ThrowingDecorator` completo.
struct Timeout: ThrowingDecorator {
    let duration: Duration
    init(_ duration: Duration) { self.duration = duration }

    func decorate<Out>(_ call: Call, _ next: () throws -> Out) throws -> Out {
        let start = ContinuousClock.now
        let out = try next()
        guard ContinuousClock.now - start <= duration else { throw AccessError.timedOut }
        return out
    }

    func decorate<Out>(_ call: Call, isolation: isolated (any Actor)?, _ next: () async throws -> Out) async throws -> Out {
        let start = ContinuousClock.now
        let out = try await next()
        guard ContinuousClock.now - start <= duration else { throw AccessError.timedOut }
        return out
    }
}
