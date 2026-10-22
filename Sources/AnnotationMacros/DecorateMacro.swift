//
//  DecorateMacro.swift
//  AnnotationMacros
//

import SwiftSyntax
import SwiftSyntaxMacros

/// `@Decorate(Logged(), Retry(3))`: la forma sin declarar marcadores.
///
/// Igual que un marcador, no genera código: `@Decorable` lee sus argumentos como la lista de
/// decoradores a aplicar, en orden, y los mezcla con los marcadores clásicos que haya alrededor.
/// Aquí solo se comprueba el contexto y que tenga al menos un argumento.
public struct DecorateMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        if case .argumentList(let arguments)? = node.arguments, !arguments.isEmpty {
            // ok
        } else {
            context.error(node, id: "emptyDecorate", "@Decorate needs at least one decorator, e.g. @Decorate(Logged(), Retry(3))")
        }
        MarkerMacro.checkContext(of: node, in: context)
        return []
    }
}
