//
//  experimental_annotation.swift
//  experimental_annotation
//
//  Created by Francisco Javier Saldivar Rubio on 31/07/21.
//


/// El protocolo abstrae el comportamiento de una annotación en Java, la cual
/// puede iniciar un valor default y procesar el comportamiento cuando sucede un setter
public protocol Annotation {
    
    /// TranformValue: función que valida y configura la transformación del valor,
    /// como el convertir todos los valores de mayuscula a minuscula, etc..
    /// - Parameter wrappedValue: Valor seteado
    /// - Returns: Valor transformado
    func tranformValue<T>(wrappedValue: T?) -> T?
    
    
    /// Actualiza el varlor wrappedValue, recuerda que este protocolo se creo con
    /// la intención de ser implementado en estructuras de tipo **@propertyWrapper**
    /// - Parameter value: wrappedValue heredado de otra anotación., este valor es invocado desde
    /// ``AnnotationGroup``
    func updateValue<T>(value: T)
}


/// AnnotationGroup es creado con la intención de lograr agrupar n cantidad de ``Annotation``
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
public protocol AnnotationGroup: AnyObject {
    var annotations: [Annotation] { get }

    func updateWrapped<T>(value: inout T?) -> T?
}

extension AnnotationGroup {
    
    public func updateWrapped<T>( value: inout T?) -> T? {
        self.annotations.forEach({ value = $0.tranformValue(wrappedValue: value) })
        self.annotations.forEach({ $0.updateValue(value: value) })
        return value
    }
}

@propertyWrapper
public class GroupSet<SetValue>: AnnotationGroup {
    private var service: SetValue?
    public var annotations: [Annotation]

    public init(_ annotations: Annotation ...) {
        self.annotations = annotations
    }
    
    public var wrappedValue: SetValue? {
        get { service}
        set {
            var updateValue = newValue
            service = updateWrapped(value: &updateValue)
        }
    }
}
