//
//  DecorableMacro.swift
//  AnnotationMacros
//

import SwiftSyntax
import SwiftSyntaxMacros

/// `@Decorable`: el procesador. Por cada miembro con marcadores adjunta la macro interna que
/// envuelve su cuerpo (`_DecoratedFunction`) o sus accesores (`_DecoratedProperty`).
public struct DecorableMacro: MemberAttributeMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {

        if declaration.is(ProtocolDeclSyntax.self) {
            if let attributed = member.asProtocol(WithAttributesSyntax.self),
               let first = Markers.markers(in: attributed.attributes).first {
                context.error(first, id: "protocol",
                              "@Decorable cannot be applied to a protocol: requirements have no body to wrap; apply it to the conforming type")
            }
            return []
        }

        if let function = member.as(FunctionDeclSyntax.self) {
            guard !Markers.markers(in: function.attributes).isEmpty else { return [] }
            return ["@AnnotationSwift._DecoratedFunction"]
        }

        if let variable = member.as(VariableDeclSyntax.self) {
            let markers = Markers.markers(in: variable.attributes)
            guard !markers.isEmpty else { return [] }
            if declaration.is(ExtensionDeclSyntax.self) {
                context.error(markers[0], id: "extension",
                              "decorators cannot be applied to properties declared in an extension")
                return []
            }
            guard StoredProperty.validate(variable, in: context) != nil else { return [] }
            return ["@AnnotationSwift._DecoratedProperty"]
        }

        // Cualquier otra declaración con marcadores no se puede decorar.
        if let attributed = member.asProtocol(WithAttributesSyntax.self) {
            let markers = Markers.markers(in: attributed.attributes)
            if let first = markers.first {
                context.error(first, id: "unsupported",
                              "decorators can only be applied to functions and stored properties")
            }
        }
        return []
    }
}
