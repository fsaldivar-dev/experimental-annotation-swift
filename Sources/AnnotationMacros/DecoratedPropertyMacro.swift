//
//  DecoratedPropertyMacro.swift
//  AnnotationMacros
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Convierte una propiedad almacenada en una computada cuyo `init` y `set` atraviesan la cadena
/// de decoradores. El almacenamiento real pasa a un peer `_nombre`, igual que hace `@Observable`.
///
/// Para `@Trimmed @Lowercased var email: String` genera:
///
///     private var _email: String
///
///     @storageRestrictions(initializes: _email)
///     init(initialValue) { _email = Trimmed().decorate(initialValue, __annotation_property) { … } }
///     get { _email }
///     set { _email = Trimmed().decorate(newValue, __annotation_property) { … } }
public struct DecoratedPropertyMacro: AccessorMacro, PeerMacro {

    // MARK: Accesores

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              let property = StoredProperty.validate(variable, in: context) else { return [] }
        let markers = Markers.markers(in: variable.attributes)
        guard !markers.isEmpty else { return [] }

        let storage = "_\(property.name)"
        let metadata = propertyExpression(for: variable, named: property.name, in: context)
        let initChain = chain(markers, value: "initialValue")
        let setChain = chain(markers, value: "newValue")

        return [
            """
            @storageRestrictions(initializes: \(raw: storage))
            init(initialValue) {
                let __annotation_property = \(raw: metadata)
                \(raw: storage) = \(raw: initChain)
            }
            """,
            """
            get {
                \(raw: storage)
            }
            """,
            """
            set {
                let __annotation_property = \(raw: metadata)
                \(raw: storage) = \(raw: setChain)
            }
            """,
        ]
    }

    // MARK: Peer (almacenamiento)

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              variable.bindings.count == 1,
              let binding = variable.bindings.first,
              variable.bindingSpecifier.tokenKind == .keyword(.var),
              binding.accessorBlock == nil,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              !Markers.markers(in: variable.attributes).isEmpty
        else { return [] }   // los diagnósticos ya los emitió el rol de accesores

        var storage = "private var _\(name)"
        if let type = binding.typeAnnotation?.type { storage += ": \(type.trimmedDescription)" }
        if let initializer = binding.initializer?.value { storage += " = \(initializer.trimmedDescription)" }
        return [DeclSyntax(stringLiteral: storage)]
    }

    // MARK: - Helpers

    /// `A().decorate(value, p) { __v in B().decorate(__v, p) { __v in __v } }`
    private static func chain(_ markers: [AttributeSyntax], value: String) -> String {
        var inner = "{ __v in __v }"
        for marker in markers.reversed() {
            let argument = marker == markers.first ? value : "__v"
            let call = "\(Markers.constructor(for: marker)).decorate(\(argument), __annotation_property) \(inner)"
            inner = marker == markers.first ? call : "{ __v in \(call) }"
        }
        return inner
    }

    private static func propertyExpression(for variable: VariableDeclSyntax, named name: String, in context: some MacroExpansionContext) -> String {
        let location = context.location(of: variable, at: .afterLeadingTrivia, filePathMode: .fileID)
        let file = location?.file.trimmedDescription ?? "\"\""
        let line = location?.line.trimmedDescription ?? "0"
        return "AnnotationSwift.Property(name: \"\(name)\", type: \"\(Enclosing.typeName(in: context))\", file: \(file), line: \(line))"
    }
}
