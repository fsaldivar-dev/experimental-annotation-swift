//
//  Decorator.swift
//  AnnotationSwift
//

/// Comportamiento que envuelve la ejecución de una función.
///
/// Un decorador recibe la invocación (``Call``) y una continuación `next` que representa
/// "lo que sigue en la cadena": el siguiente decorador apilado o, al final, el cuerpo original.
/// El decorador decide si llama a `next` una vez, varias (reintentos), o ninguna (caché).
///
/// Hay dos requisitos porque Swift no permite esperar (`await`) dentro de una función
/// síncrona: uno para funciones síncronas y otro para funciones `async`. La macro elige el
/// correcto según la firma de la función decorada. Si tu decorador solo necesita observar
/// la llamada (antes, después, al fallar) conforma ``HookDecorator`` y escribe una sola vez.
///
/// Ambos requisitos son `rethrows`: el decorador es transparente y solo lanza lo que lance
/// `next`, por eso sirve también en funciones que no lanzan. Si necesitas lanzar por tu cuenta
/// (un guardián, un timeout) usa ``ThrowingDecorator`` o ``GuardDecorator``.
///
/// Para registrar el decorador como anotación, declara un marcador con el mismo nombre
/// que el tipo:
///
/// ```swift
/// struct Retry: Decorator {
///     let attempts: Int
///     init(_ attempts: Int) { self.attempts = attempts }
///
///     func decorate<Out>(_ call: Call, _ next: () throws -> Out) rethrows -> Out {
///         for _ in 1..<attempts { if let out = try? next() { return out } }
///         return try next()
///     }
///
///     func decorate<Out>(_ call: Call, isolation: isolated (any Actor)?,
///                        _ next: () async throws -> Out) async rethrows -> Out {
///         for _ in 1..<attempts { if let out = try? await next() { return out } }
///         return try await next()
///     }
/// }
///
/// @attached(peer) macro Retry(_ attempts: Int) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
/// ```
///
/// La macro genera `Retry(3)` a partir de `@Retry(3)`, así que los argumentos del marcador
/// deben coincidir con un inicializador del tipo.
public protocol Decorator {

    /// Envuelve una función síncrona.
    ///
    /// - Parameters:
    ///   - call: Metadatos de la invocación.
    ///   - next: Continuación de la cadena. Devuelve el resultado de la función.
    /// - Returns: El valor que la función decorada devolverá a quien la llamó.
    func decorate<Out>(_ call: Call, _ next: () throws -> Out) rethrows -> Out

    /// Envuelve una función `async`.
    ///
    /// Se ejecuta en el mismo aislamiento que la función decorada (`isolation`), de modo que
    /// `next` puede tocar estado del actor sin cruzar fronteras. La macro pasa `#isolation`.
    ///
    /// - Parameters:
    ///   - call: Metadatos de la invocación.
    ///   - isolation: Actor en el que corre la función decorada, o `nil` si no está aislada.
    ///   - next: Continuación de la cadena.
    func decorate<Out>(
        _ call: Call,
        isolation: isolated (any Actor)?,
        _ next: () async throws -> Out
    ) async rethrows -> Out
}

/// Decorador que solo observa la llamada: antes, al devolver y al fallar.
///
/// Implementa los ganchos que te interesen y obtienes gratis ambas variantes de
/// ``Decorator/decorate(_:_:)`` y ``Decorator/decorate(_:isolation:_:)``.
///
/// ```swift
/// struct Logged: HookDecorator {
///     func willCall(_ call: Call) { print("→ \(call)") }
///     func didReturn(_ call: Call, result: Any) { print("← \(call) = \(result)") }
///     func didThrow(_ call: Call, error: any Error) { print("✗ \(call): \(error)") }
/// }
/// ```
public protocol HookDecorator: Decorator {
    /// Se invoca antes de ejecutar la continuación.
    func willCall(_ call: Call)
    /// Se invoca cuando la continuación devuelve sin error.
    func didReturn(_ call: Call, result: Any)
    /// Se invoca cuando la continuación lanza un error. El error se propaga después.
    func didThrow(_ call: Call, error: any Error)
}

extension HookDecorator {
    public func willCall(_ call: Call) {}
    public func didReturn(_ call: Call, result: Any) {}
    public func didThrow(_ call: Call, error: any Error) {}

    public func decorate<Out>(_ call: Call, _ next: () throws -> Out) rethrows -> Out {
        willCall(call)
        do {
            let result = try next()
            didReturn(call, result: result)
            return result
        } catch {
            didThrow(call, error: error)
            throw error
        }
    }

    public func decorate<Out>(
        _ call: Call,
        isolation: isolated (any Actor)?,
        _ next: () async throws -> Out
    ) async rethrows -> Out {
        willCall(call)
        do {
            let result = try await next()
            didReturn(call, result: result)
            return result
        } catch {
            didThrow(call, error: error)
            throw error
        }
    }
}
