//
//  DecoratedFunctionMacro.swift
//  AnnotationMacros
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Envuelve el cuerpo de una función con la cadena de decoradores que marcan la declaración.
///
/// Para `@Logged @Retry(3) func fetch() async throws -> Int { … }` genera:
///
///     let __annotation_call = AnnotationSwift.Call(function: "fetch()", type: "Service", file: …, line: …)
///     return try await Logged().decorate(__annotation_call, isolation: #isolation) { () async throws -> Int in
///         return try await Retry(3).decorate(__annotation_call, isolation: #isolation) { () async throws -> Int in
///             …cuerpo original…
///         }
///     }
public struct DecoratedFunctionMacro: BodyMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {

        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            context.error(node, id: "notFunction", "decorators can only wrap functions")
            return []
        }
        guard let body = function.body else {
            context.error(function, id: "noBody", "decorators require a function body")
            return []
        }
        let original = Array(body.statements)
        let markers = Markers.markers(in: function.attributes)
        guard !markers.isEmpty else { return original }

        let effects = function.signature.effectSpecifiers
        if let typed = effects?.throwsClause?.type {
            context.error(typed, id: "typedThrows",
                          "decorators do not support typed throws; declare the function as 'throws'")
            return original
        }
        let isAsync = effects?.asyncSpecifier != nil
        let isThrows = effects?.throwsClause != nil

        let prefix = (isThrows ? "try " : "") + (isAsync ? "await " : "")
        let closureEffects = (isAsync ? " async" : "") + (isThrows ? " throws" : "")
        let closureSignature = "()\(closureEffects)\(returnClause(for: function)) in"
        let isolation = isAsync ? ", isolation: #isolation" : ""

        // Cadena de adentro hacia afuera: el último marcador envuelve directamente al cuerpo.
        var chain: String = original.map { $0.trimmedDescription }.joined(separator: "\n")
        for marker in markers.reversed() {
            chain = """
            return \(prefix)\(Markers.constructor(for: marker)).decorate(__annotation_call\(isolation)) { \(closureSignature)
            \(chain)
            }
            """
        }

        return [
            "let __annotation_call = \(raw: callExpression(for: function, in: context))",
            "\(raw: chain)",
        ]
    }

    // MARK: - Helpers

    /// `-> T` explícito para ayudar a la inferencia de `Out`; se omite con tipos opacos o `Self`.
    private static func returnClause(for function: FunctionDeclSyntax) -> String {
        guard let type = function.signature.returnClause?.type else { return " -> Void" }
        let opaque = type.tokens(viewMode: .sourceAccurate).contains { token in
            token.tokenKind == .keyword(.some) || token.tokenKind == .keyword(.Self)
        }
        return opaque ? "" : " -> \(type.trimmedDescription)"
    }

    private static func callExpression(for function: FunctionDeclSyntax, in context: some MacroExpansionContext) -> String {
        let parameters = function.signature.parameterClause.parameters
        let signature = function.name.text + "(" + parameters.map { "\($0.firstName.text):" }.joined() + ")"
        let location = context.location(of: function, at: .afterLeadingTrivia, filePathMode: .fileID)
        let file = location?.file.trimmedDescription ?? "\"\""
        let line = location?.line.trimmedDescription ?? "0"

        let arguments = parameters.compactMap { parameter -> String? in
            // Los closures no escapantes no se pueden guardar en `Any`; se omiten.
            var type = parameter.type
            while let attributed = type.as(AttributedTypeSyntax.self) { type = attributed.baseType }
            if type.is(FunctionTypeSyntax.self) { return nil }

            let internalName = (parameter.secondName ?? parameter.firstName).text
            guard internalName != "_" else { return nil }
            let label = parameter.firstName.text == "_" ? "nil" : "\"\(parameter.firstName.text)\""
            return "AnnotationSwift.Call.Argument(name: \"\(internalName)\", label: \(label), value: \(internalName))"
        }

        var expression = "AnnotationSwift.Call(function: \"\(signature)\", type: \"\(Enclosing.typeName(in: context))\", file: \(file), line: \(line)"
        if !arguments.isEmpty {
            expression += ", arguments: [\(arguments.joined(separator: ", "))]"
        }
        return expression + ")"
    }
}
