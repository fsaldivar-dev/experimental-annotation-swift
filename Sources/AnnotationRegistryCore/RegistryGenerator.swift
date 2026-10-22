//
//  RegistryGenerator.swift
//  AnnotationRegistryCore
//
//  Encuentra los tipos marcados con `@Annotation` y escribe, por cada uno, la declaración de
//  macro marcador que el compilador exige para poder escribir `@Logged` sobre una función:
//
//      @attached(peer) macro Logged() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
//
//  Lo ejecuta el build-tool plugin `AnnotationRegistry` antes de compilar cada módulo.
//

import SwiftParser
import SwiftSyntax

public struct RegistryGenerator {

    public init() {}

    /// Declaraciones de macro para todos los tipos `@Annotation` de los fuentes dados.
    public func generate(sources: [(path: String, text: String)]) -> String {
        var declarations: [String] = []
        for source in sources {
            let tree = Parser.parse(source: source.text)
            let visitor = AnnotationVisitor(viewMode: .sourceAccurate)
            visitor.walk(tree)
            for type in visitor.annotated {
                declarations.append(contentsOf: Self.declarations(for: type))
            }
        }
        var output = """
        // Generado por AnnotationSwift (plugin AnnotationRegistry). No editar.
        // Una declaración de macro marcador por cada tipo @Annotation del módulo.
        import AnnotationSwift

        """
        if declarations.isEmpty {
            output += "// (ningún tipo @Annotation en este módulo)\n"
        } else {
            output += declarations.joined(separator: "\n") + "\n"
        }
        return output
    }

    // MARK: - Una declaración por inicializador

    static func declarations(for type: AnnotatedType) -> [String] {
        let access = type.isPublic ? "public " : ""
        let generics = type.genericParameters ?? ""
        let whereClause = type.genericWhere.map { " " + $0 } ?? ""
        let signatures = type.initializerSignatures.isEmpty ? ["()"] : type.initializerSignatures
        return signatures.map { parameters in
            "@attached(peer) \(access)macro \(type.name)\(generics)\(parameters)\(whereClause) = #externalMacro(module: \"AnnotationMacros\", type: \"MarkerMacro\")"
        }
    }
}

/// Lo que el generador necesita saber de un tipo marcado.
public struct AnnotatedType: Equatable {
    public var name: String
    public var isPublic: Bool
    public var genericParameters: String?
    public var genericWhere: String?
    /// Lista de parámetros de cada `init` explícito, o del memberwise si no hay ninguno.
    public var initializerSignatures: [String]
}

final class AnnotationVisitor: SyntaxVisitor {
    var annotated: [AnnotatedType] = []

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        collect(name: node.name.text, attributes: node.attributes, modifiers: node.modifiers,
                generics: node.genericParameterClause, whereClause: node.genericWhereClause, members: node.memberBlock)
        return .skipChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        collect(name: node.name.text, attributes: node.attributes, modifiers: node.modifiers,
                generics: node.genericParameterClause, whereClause: node.genericWhereClause, members: node.memberBlock)
        return .skipChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        collect(name: node.name.text, attributes: node.attributes, modifiers: node.modifiers,
                generics: node.genericParameterClause, whereClause: node.genericWhereClause, members: node.memberBlock)
        return .skipChildren
    }

    private func collect(name: String, attributes: AttributeListSyntax, modifiers: DeclModifierListSyntax,
                         generics: GenericParameterClauseSyntax?, whereClause: GenericWhereClauseSyntax?, members: MemberBlockSyntax) {
        let isAnnotation = attributes.contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else { return false }
            let typeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
                ?? attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
            return typeName == "Annotation"
        }
        guard isAnnotation else { return }

        let isPublic = modifiers.contains { $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.open) }

        // init explícitos (sin los privados)
        var signatures: [String] = []
        var storedWithoutDefault: [String] = []
        for member in members.members {
            if let initializer = member.decl.as(InitializerDeclSyntax.self) {
                let isPrivate = initializer.modifiers.contains { $0.name.tokenKind == .keyword(.private) || $0.name.tokenKind == .keyword(.fileprivate) }
                if !isPrivate { signatures.append(initializer.signature.parameterClause.trimmedDescription) }
            } else if let variable = member.decl.as(VariableDeclSyntax.self),
                      !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
                for binding in variable.bindings where binding.accessorBlock == nil {
                    guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                          let type = binding.typeAnnotation?.type.trimmedDescription else { continue }
                    let isLetWithValue = variable.bindingSpecifier.tokenKind == .keyword(.let) && binding.initializer != nil
                    if isLetWithValue { continue }
                    if let initializer = binding.initializer {
                        storedWithoutDefault.append("\(identifier): \(type) = \(initializer.value.trimmedDescription)")
                    } else {
                        storedWithoutDefault.append("\(identifier): \(type)")
                    }
                }
            }
        }
        if signatures.isEmpty {
            // memberwise: solo tiene sentido en structs; para clases sin init no hay firma
            signatures = ["(" + storedWithoutDefault.joined(separator: ", ") + ")"]
        }

        annotated.append(AnnotatedType(
            name: name,
            isPublic: isPublic,
            genericParameters: generics?.trimmedDescription,
            genericWhere: whereClause?.trimmedDescription,
            initializerSignatures: signatures
        ))
    }
}
