//
//  Call.swift
//  AnnotationSwift
//

/// Metadatos de la invocación de una función decorada.
///
/// La macro construye un `Call` en cada llamada y se lo entrega a cada ``Decorator``
/// de la cadena. Es el equivalente al *JoinPoint* de la programación orientada a aspectos:
/// describe *qué* se está ejecutando sin que el decorador tenga que saber nada del tipo.
///
/// `Call` no es `Sendable` porque ``Call/arguments`` transporta los valores reales de los
/// parámetros, que pueden no serlo. Si un decorador necesita cruzar fronteras de aislamiento,
/// debe extraer antes lo que necesite (por ejemplo ``Call/description``).
public struct Call {

    /// Un argumento de la invocación.
    public struct Argument {
        /// Nombre interno del parámetro, el que usa el cuerpo de la función.
        public let name: String
        /// Etiqueta externa del parámetro, o `nil` si se declaró con `_`.
        public let label: String?
        /// Valor recibido en esta invocación.
        public let value: Any

        public init(name: String, label: String?, value: Any) {
            self.name = name
            self.label = label
            self.value = value
        }
    }

    /// Nombre completo de la función, con sus etiquetas: `"fetch(id:)"`.
    public let function: String
    /// Nombre del tipo que contiene la función, por ejemplo `"Service"`.
    public let type: String
    /// Archivo donde está declarada la función, en formato `#fileID`.
    public let file: String
    /// Línea donde está declarada la función.
    public let line: Int
    /// Argumentos recibidos, en el orden de la firma. Los parámetros de tipo función se omiten.
    public let arguments: [Argument]

    public init(function: String, type: String, file: String, line: Int, arguments: [Argument] = []) {
        self.function = function
        self.type = type
        self.file = file
        self.line = line
        self.arguments = arguments
    }
}

extension Call: CustomStringConvertible {
    /// `"Service.fetch(id:)"`.
    public var description: String { "\(type).\(function)" }
}

extension Call.Argument: CustomStringConvertible {
    /// `"id: 42"`.
    public var description: String { "\(label ?? name): \(value)" }
}
