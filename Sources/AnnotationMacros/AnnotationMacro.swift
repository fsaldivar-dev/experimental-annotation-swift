//
//  AnnotationMacro.swift
//  AnnotationMacros
//

import SwiftSyntax
import SwiftSyntaxMacros

/// `@Annotation` sobre el tipo de un decorador. No genera código: una macro no puede declarar
/// otra macro. Es la marca que lee el build-tool plugin `AnnotationRegistry` para generar la
/// declaración `@attached(peer) macro Logged() = …` y que `@Logged` se pueda escribir directo.
public struct AnnotationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let isType = declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) || declaration.is(EnumDeclSyntax.self)
        if !isType {
            context.error(node, id: "annotationTarget", "@Annotation marks the type of a decorator (struct, class or enum)")
        }
        return []
    }
}
