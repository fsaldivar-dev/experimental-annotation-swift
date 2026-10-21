//
//  Decorators.swift
//  Demo
//
//  Tres decoradores de función y dos de propiedad. Cada uno es un tipo normal
//  más una línea que lo registra como anotación.
//

import AnnotationSwift
import Foundation

// MARK: - Registro

@attached(peer) macro Logged() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Retry(_ attempts: Int) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Measured() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Trimmed() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Lowercased() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")

// MARK: - Función

/// Imprime entrada, salida y error. Con `HookDecorator` basta con los ganchos.
struct Logged: HookDecorator {
    func willCall(_ call: Call) {
        let arguments = call.arguments.map(\.description).joined(separator: ", ")
        print("→ \(call)  [\(arguments)]")
    }
    func didReturn(_ call: Call, result: Any) { print("← \(call) = \(result)") }
    func didThrow(_ call: Call, error: any Error) { print("✗ \(call): \(error)") }
}

/// Reintenta hasta `attempts` veces. Controla la continuación, así que implementa las dos variantes.
struct Retry: Decorator {
    let attempts: Int
    init(_ attempts: Int) { self.attempts = attempts }

    func decorate<Out>(_ call: Call, _ next: () throws -> Out) rethrows -> Out {
        for attempt in 1..<attempts {
            do { return try next() } catch { print("  intento \(attempt) de \(call.function) falló: \(error)") }
        }
        return try next()
    }

    func decorate<Out>(_ call: Call, isolation: isolated (any Actor)?, _ next: () async throws -> Out) async rethrows -> Out {
        for attempt in 1..<attempts {
            do { return try await next() } catch { print("  intento \(attempt) de \(call.function) falló: \(error)") }
        }
        return try await next()
    }
}

/// Mide la duración. Solo necesita "antes" y "después", pero quiere el tiempo entre ambos,
/// así que implementa `decorate` directamente.
struct Measured: Decorator {
    func decorate<Out>(_ call: Call, _ next: () throws -> Out) rethrows -> Out {
        let start = ContinuousClock.now
        defer { print("⏱ \(call.function) tardó \(ContinuousClock.now - start)") }
        return try next()
    }
    func decorate<Out>(_ call: Call, isolation: isolated (any Actor)?, _ next: () async throws -> Out) async rethrows -> Out {
        let start = ContinuousClock.now
        defer { print("⏱ \(call.function) tardó \(ContinuousClock.now - start)") }
        return try await next()
    }
}

// MARK: - Propiedad

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
