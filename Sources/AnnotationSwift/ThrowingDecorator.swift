//
//  ThrowingDecorator.swift
//  AnnotationSwift
//

/// Decorador que puede fallar por su cuenta, no solo propagar el error del cuerpo.
///
/// ``Decorator`` es transparente: es `rethrows`, así que solo lanza si la continuación lanza, y
/// por eso se puede aplicar a funciones que no lanzan. Un guardián, un timeout o un circuit
/// breaker necesitan lanzar *antes* o *en lugar* de ejecutar el cuerpo; eso exige `throws`
/// y, en consecuencia, que la función decorada sea `throws`. Si aplicas un `ThrowingDecorator`
/// a una función que no lanza, el compilador lo rechaza en el código generado.
///
/// La macro genera la misma llamada para ambos protocolos; el tipo decide cuál se resuelve.
/// Si tu decorador solo necesita comprobar una condición antes de ejecutar, conforma
/// ``GuardDecorator`` y escribe únicamente `check`.
public protocol ThrowingDecorator {

    /// Envuelve una función síncrona que lanza.
    func decorate<Out>(_ call: Call, _ next: () throws -> Out) throws -> Out

    /// Envuelve una función `async throws`, en el mismo aislamiento que ella.
    func decorate<Out>(
        _ call: Call,
        isolation: isolated (any Actor)?,
        _ next: () async throws -> Out
    ) async throws -> Out
}

/// Guardián: comprueba una condición y, si no se cumple, lanza y el cuerpo nunca se ejecuta.
///
/// ```swift
/// struct Authorized: GuardDecorator {
///     let role: Role
///     init(_ role: Role) { self.role = role }
///
///     func check(_ call: Call) throws {
///         guard Session.current?.roles.contains(role) == true else { throw AccessError.forbidden }
///     }
/// }
///
/// @attached(peer) macro Authorized(_ role: Role) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
/// ```
///
/// Las funciones marcadas con un guardián deben ser `throws`.
public protocol GuardDecorator: ThrowingDecorator {
    /// Se invoca antes de la continuación. Lanza para detener la ejecución.
    func check(_ call: Call) throws
}

extension GuardDecorator {
    public func decorate<Out>(_ call: Call, _ next: () throws -> Out) throws -> Out {
        try check(call)
        return try next()
    }

    public func decorate<Out>(
        _ call: Call,
        isolation: isolated (any Actor)?,
        _ next: () async throws -> Out
    ) async throws -> Out {
        try check(call)
        return try await next()
    }
}
