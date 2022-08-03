//
//  experimental_annotation.swift
//  experimental_annotation
//
//  Created by Francisco Javier Saldivar Rubio on 31/07/21.
//

public protocol ASAnnotationWrapped: ASAnnotation {
    associatedtype Element
    var wrappedValue: Element? { set get }
}

extension ASAnnotationWrapped {

    private mutating func setValue(value: Element) {
        wrappedValue = value
    }

    func tranformValue<T>(wrappedValue: T?) -> T? {
        wrappedValue
    }

    public mutating func updateValue<T>(value: T) {
        guard let value = value as? Element else {
            return
        }
        wrappedValue = value
    }
}

/// El protocolo abstrae el comportamiento de una annotación en Java, la cual
/// puede iniciar un valor default y procesar el comportamiento cuando sucede un setter
public protocol ASAnnotation {

    /// TranformValue: función que valida y configura la transformación del valor,
    /// como el convertir todos los valores de mayuscula a minuscula, etc..
    /// - Parameter wrappedValue: Valor seteado
    /// - Returns: Valor transformado
    func tranformValue<T>(wrappedValue: T?) -> T?

    /// Actualiza el varlor wrappedValue, recuerda que este protocolo se creo con
    /// la intención de ser implementado en estructuras de tipo **@propertyWrapper**
    /// - Parameter value: wrappedValue heredado de otra anotación., este valor es invocado desde
    /// ``ASAnnotationGroup``
    mutating func updateValue<T>(value: T)
}

/// AnnotationGroup es creado con la intención de lograr agrupar n cantidad de ``ASAnnotation``
///  protocolo se se implementa en un ``@propertyWrapper``.
///
///     Ejemplo:
///     struct Mock2Model {
///         @GroupSet(Email<String>(),
///                   LowCase<String>())
///         var email: String?
///         @GroupSet(MinLength<String>(minLength: 3),
///                   MaxLength<String>(maxLength: 10))
///         var min3Max10: String?
///    }
///
public protocol ASAnnotationGroup {

    /// Lista de anotaciones, ejemplo
    ///         @GroupSet(Email<String>(),
    ///                   LowCase<String>())
    var annotations: [ASAnnotation] { get }

    ///  Función que recorre toda la lista de anotaciones y ejecuta la función `tranformValue` de ``ASAnnotation``
    ///  y actualiza el valor de las copias de `wrappedValue`ejecutando la función `updateValue` de ``ASAnnotation``
    /// - Parameter value: `wrappedValue`del ``@propertyWrapper``.
    /// - Returns:  `wrappedValue` con las converciónes aplicadas de cada ``Annotation``
    mutating func updateWrapped<T>(value: inout T?) -> T?
}

extension ASAnnotationGroup {

    mutating public func updateWrapped<T>( value: inout T?) -> T? {
        self.annotations.forEach({ value = $0.tranformValue(wrappedValue: value) })
        for var item in annotations {
            item.updateValue(value: value)
        }
        return value
    }
}

@propertyWrapper
/// `ASGroup` es una ``@propertyWrapper`` que agrupa ``ASAnnotation``
///
///     Ejemplo:
///         @GroupSet(Email<String>(),
///                   LowCase<String>())
///         var email: String?
///         @LowCase
///         var userName: String?
///    }
///
public struct ASGroup<SetValue>: ASAnnotationGroup {

    private var service: SetValue?
    public var annotations: [ASAnnotation]

    public var wrappedValue: SetValue? {
        get { service }
        set {
            var updateValue = newValue
            service = updateWrapped(value: &updateValue)
        }
    }

    /// ``@propertyWrapper`` `ASGroup` solo se podra construir con una lista de ``ASAnnotation``
    /// - Parameter annotations: lista de ``ASAnnotation``
    public init(_ annotations: ASAnnotation ...) {
        self.annotations = annotations
    }
}
