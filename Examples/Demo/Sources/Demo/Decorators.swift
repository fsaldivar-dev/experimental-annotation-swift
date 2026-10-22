//
//  Decorators.swift
//  Demo
//
//  Tres decoradores de función y dos de propiedad. Cada uno es un tipo normal marcado con
//  @Annotation: el plugin AnnotationRegistry (activado en Package.swift) genera por ellos la
//  declaración de marcador, así que `@Logged` o `@Retry(3)` se escriben directo.
//

import AnnotationSwift
import Foundation

// MARK: - Función

/// Imprime entrada, salida y error. Con `HookDecorator` basta con los ganchos.
@Annotation
struct Logged: HookDecorator {
    func willCall(_ call: Call) {
        let arguments = call.arguments.map(\.description).joined(separator: ", ")
        print("→ \(call)  [\(arguments)]")
    }
    func didReturn(_ call: Call, result: Any) { print("← \(call) = \(result)") }
    func didThrow(_ call: Call, error: any Error) { print("✗ \(call): \(error)") }
}

/// Reintenta hasta `attempts` veces. Controla la continuación, así que implementa las dos variantes.
@Annotation
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
@Annotation
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

@Annotation
struct Trimmed: PropertyDecorator {
    func decorate(_ value: String, _ property: Property, next: (String) -> String) -> String {
        next(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

@Annotation
struct Lowercased: PropertyDecorator {
    func decorate(_ value: String, _ property: Property, next: (String) -> String) -> String {
        next(value.lowercased())
    }
}
