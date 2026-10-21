//
//  MarkerMacro.swift
//  AnnotationMacros
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Marcador genérico. Toda anotación de usuario apunta aquí:
///
///     @attached(peer) macro Logged() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
///
/// No genera código: deja el atributo en la declaración para que `@Decorable` lo lea.
/// Su único trabajo es avisar cuando el marcador no tendrá efecto porque el tipo
/// contenedor no es `@Decorable`.
public struct MarkerMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let name = Markers.simpleName(of: node) ?? node.attributeName.trimmedDescription
        guard let group = Enclosing.group(in: context) else {
            context.error(node, id: "topLevel",
                          "'@\(name)' has no effect here: decorators can only be applied to members of a @Decorable type")
            return []
        }
        if !Markers.has("Decorable", in: group.attributes) {
            context.error(node, id: "notDecorable",
                          "'@\(name)' has no effect: add @Decorable to '\(Enclosing.name(of: group))'")
        }
        return []
    }
}
