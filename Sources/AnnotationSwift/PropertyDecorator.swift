//
//  PropertyDecorator.swift
//  AnnotationSwift
//

/// Comportamiento que envuelve la asignación de una propiedad almacenada.
///
/// Cada vez que la propiedad se inicializa o se asigna, el valor nuevo atraviesa la cadena de
/// decoradores en el orden en que están apilados; el último `next` es el almacenamiento.
/// Un decorador transforma el valor y se lo pasa a `next`, o devuelve otro sin llamarlo.
///
/// ```swift
/// struct Trimmed: PropertyDecorator {
///     func decorate(_ value: String, _ property: Property, next: (String) -> String) -> String {
///         next(value.trimmingCharacters(in: .whitespacesAndNewlines))
///     }
/// }
///
/// @attached(peer) macro Trimmed() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
/// ```
///
/// El tipo ``Value`` fija sobre qué propiedades se puede usar el decorador. Un decorador
/// genérico (`struct Clamped<Value: Comparable>`) sirve para cualquier tipo que cumpla la
/// restricción.
public protocol PropertyDecorator {
    /// Tipo de la propiedad que este decorador sabe tratar.
    associatedtype Value

    /// Envuelve la asignación.
    ///
    /// - Parameters:
    ///   - value: Valor que se intenta asignar (ya transformado por los decoradores exteriores).
    ///   - property: Metadatos de la propiedad.
    ///   - next: Continuación de la cadena. Devuelve el valor que finalmente se almacenará.
    /// - Returns: El valor que se almacenará en la propiedad.
    func decorate(_ value: Value, _ property: Property, next: (Value) -> Value) -> Value
}
