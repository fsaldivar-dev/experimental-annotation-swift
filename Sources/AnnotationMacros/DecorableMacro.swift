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
               let first = Markers.firstDecoratorAttribute(in: attributed.attributes) {
                context.error(first, id: "protocol",
                              "@Decorable cannot be applied to a protocol: requirements have no body to wrap; apply it to the conforming type")
            }
            return []
        }

        // `@Decorate()` vacío lo diagnostica DecorateMacro; aquí solo se ignora.
        if let attributed = member.asProtocol(WithAttributesSyntax.self),
           Markers.emptyDecorate(in: attributed.attributes) != nil {
            return []
        }

        if let function = member.as(FunctionDeclSyntax.self) {
            guard Markers.hasDecorators(in: function.attributes) else { return [] }
            return ["@AnnotationSwift._DecoratedFunction"]
        }

        if let variable = member.as(VariableDeclSyntax.self) {
            guard let first = Markers.firstDecoratorAttribute(in: variable.attributes) else { return [] }
            if declaration.is(ExtensionDeclSyntax.self) {
                context.error(first, id: "extension",
                              "decorators cannot be applied to properties declared in an extension")
                return []
            }
            guard StoredProperty.validate(variable, in: context) != nil else { return [] }
            return ["@AnnotationSwift._DecoratedProperty"]
        }

        // Cualquier otra declaración con marcadores no se puede decorar.
        if let attributed = member.asProtocol(WithAttributesSyntax.self),
           let first = Markers.firstDecoratorAttribute(in: attributed.attributes) {
            context.error(first, id: "unsupported",
                          "decorators can only be applied to functions and stored properties")
        }
        return []
    }
}
