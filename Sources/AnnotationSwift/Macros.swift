//
//  Macros.swift
//  AnnotationSwift
//

/// Activa las anotaciones apiladas en los miembros de un tipo o extensión.
///
/// `@Decorable` es el procesador: recorre los miembros, detecta los marcadores
/// (`@Logged`, `@Retry(3)`, `@Trimmed`, …) y envuelve cada función o propiedad con la cadena
/// de decoradores correspondiente, en el orden en que están escritos. Sin `@Decorable`, los
/// marcadores no tienen efecto y el compilador lo señala.
///
/// ```swift
/// @Decorable
/// struct Service {
///     @Logged
///     @Retry(3)
///     func fetch() async throws -> Data { … }
///
///     @Trimmed
///     @Lowercased
///     var email: String
/// }
/// ```
///
/// Reglas:
/// - Funciones: cualquier método de instancia o estático, síncrono o `async`, con o sin `throws`.
///   No se admiten `init`, `subscript` ni `throws(E)` tipado.
/// - Propiedades: solo `var` almacenadas de instancia. No `let`, ni computadas, ni `static`/`lazy`.
///   En una extensión no se pueden decorar propiedades porque no pueden tener almacenamiento.
/// - Cualquier atributo con mayúscula inicial que no sea del compilador (`@MainActor`,
///   `@IBAction`, …) se considera un marcador; el tipo con ese nombre debe conformar
///   ``Decorator`` o ``PropertyDecorator``.
/// - `@Decorable` no se aplica a un `protocol`. Los marcadores dentro de un protocolo son
///   inertes: otra macro puede leerlos y transcribirlos a la implementación que genere.
@attached(memberAttribute)
public macro Decorable() = #externalMacro(module: "AnnotationMacros", type: "DecorableMacro")

/// Macro interna que ``Decorable()`` adjunta a cada función con marcadores. No la uses directamente.
@attached(body)
public macro _DecoratedFunction() = #externalMacro(module: "AnnotationMacros", type: "DecoratedFunctionMacro")

/// Macro interna que ``Decorable()`` adjunta a cada propiedad con marcadores. No la uses directamente.
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(_))
public macro _DecoratedProperty() = #externalMacro(module: "AnnotationMacros", type: "DecoratedPropertyMacro")
