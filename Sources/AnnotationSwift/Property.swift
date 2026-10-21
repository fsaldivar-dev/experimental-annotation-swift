//
//  Property.swift
//  AnnotationSwift
//

/// Metadatos de una propiedad decorada.
///
/// La macro construye un `Property` y se lo entrega a cada ``PropertyDecorator`` de la cadena
/// cada vez que la propiedad se inicializa o se asigna.
public struct Property: Sendable, Hashable {

    /// Nombre de la propiedad, por ejemplo `"email"`.
    public let name: String
    /// Nombre del tipo que contiene la propiedad, por ejemplo `"User"`.
    public let type: String
    /// Archivo donde está declarada la propiedad, en formato `#fileID`.
    public let file: String
    /// Línea donde está declarada la propiedad.
    public let line: Int

    public init(name: String, type: String, file: String, line: Int) {
        self.name = name
        self.type = type
        self.file = file
        self.line = line
    }
}

extension Property: CustomStringConvertible {
    /// `"User.email"`.
    public var description: String { "\(type).\(name)" }
}
