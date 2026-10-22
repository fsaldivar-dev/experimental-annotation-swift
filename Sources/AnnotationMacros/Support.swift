//
//  Support.swift
//  AnnotationMacros
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Diagnósticos

struct AnnotationDiagnostic: DiagnosticMessage {
    let message: String
    let id: String
    var severity: DiagnosticSeverity { .error }
    var diagnosticID: MessageID { MessageID(domain: "AnnotationSwift", id: id) }
}

extension MacroExpansionContext {
    func error(_ node: some SyntaxProtocol, id: String, _ message: String) {
        diagnose(Diagnostic(node: Syntax(node), message: AnnotationDiagnostic(message: message, id: id)))
    }
}

// MARK: - Reconocimiento de marcadores

enum Markers {

    /// Atributos con mayúscula inicial que pertenecen al compilador, al SDK o a esta librería
    /// y por tanto nunca son decoradores. Los atributos con minúscula inicial (`@available`,
    /// `@objc`, `@discardableResult`, …) y los que empiezan con `_` se descartan por regla.
    static let knownAttributes: Set<String> = [
        // Concurrencia / lenguaje
        "MainActor", "Sendable",
        // Interface Builder / Objective-C
        "IBAction", "IBOutlet", "IBDesignable", "IBInspectable", "IBSegueAction",
        "NSManaged", "NSCopying", "NSApplicationMain", "UIApplicationMain", "GKInspectable",
        // Observation / SwiftData / Testing
        "Observable", "ObservationTracked", "ObservationIgnored",
        "Model", "Attribute", "Relationship", "Transient",
        "Test", "Suite",
        // SwiftUI (property wrappers habituales dentro de un tipo decorable)
        "State", "Binding", "ObservedObject", "StateObject", "Environment", "EnvironmentObject",
        "AppStorage", "SceneStorage", "FocusState", "Published",
        // Esta librería
        "Decorable", "Decorate", "Annotation", "_DecoratedFunction", "_DecoratedProperty",
    ]

    /// Nombre simple del atributo: para `@AnnotationSwift.Decorable` devuelve `Decorable`.
    static func simpleName(of attribute: AttributeSyntax) -> String? {
        if let id = attribute.attributeName.as(IdentifierTypeSyntax.self) {
            return id.name.text
        }
        if let member = attribute.attributeName.as(MemberTypeSyntax.self) {
            return member.name.text
        }
        return nil
    }

    static func isMarker(_ attribute: AttributeSyntax) -> Bool {
        guard let name = simpleName(of: attribute), let first = name.first else { return false }
        guard first.isUppercase else { return false }
        return !knownAttributes.contains(name)
    }

    static func markers(in attributes: AttributeListSyntax) -> [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }.filter(isMarker)
    }

    /// Un decorador a aplicar: la expresión que lo construye y el nodo de donde salió.
    struct Reference {
        let expression: String
        let node: Syntax
    }

    /// Decoradores de una declaración, en orden de escritura, uniendo las dos formas:
    /// marcadores (`@Retry(3)` → `Retry(3)`) y `@Decorate(Logged(), Retry(3))` (sus argumentos tal cual).
    static func decorators(in attributes: AttributeListSyntax) -> [Reference] {
        var references: [Reference] = []
        for element in attributes {
            guard let attribute = element.as(AttributeSyntax.self) else { continue }
            if simpleName(of: attribute) == "Decorate" {
                if case .argumentList(let arguments)? = attribute.arguments {
                    for argument in arguments {
                        references.append(Reference(expression: argument.expression.trimmedDescription, node: Syntax(argument.expression)))
                    }
                }
            } else if isMarker(attribute) {
                references.append(Reference(expression: constructor(for: attribute), node: Syntax(attribute)))
            }
        }
        return references
    }

    /// `@Decorate` sin argumentos, para diagnosticarlo.
    static func emptyDecorate(in attributes: AttributeListSyntax) -> AttributeSyntax? {
        attributes.lazy.compactMap { $0.as(AttributeSyntax.self) }.first { attribute in
            guard simpleName(of: attribute) == "Decorate" else { return false }
            if case .argumentList(let arguments)? = attribute.arguments { return arguments.isEmpty }
            return true
        }
    }

    /// ¿Hay algo que decorar? (marcadores o un `@Decorate`).
    static func hasDecorators(in attributes: AttributeListSyntax) -> Bool {
        attributes.contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else { return false }
            return simpleName(of: attribute) == "Decorate" || isMarker(attribute)
        }
    }

    /// Primer atributo decorador, para anclar diagnósticos.
    static func firstDecoratorAttribute(in attributes: AttributeListSyntax) -> AttributeSyntax? {
        attributes.lazy.compactMap { $0.as(AttributeSyntax.self) }.first { simpleName(of: $0) == "Decorate" || isMarker($0) }
    }

    static func has(_ name: String, in attributes: AttributeListSyntax) -> Bool {
        attributes.contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else { return false }
            return simpleName(of: attribute) == name
        }
    }

    /// Expresión que construye el decorador a partir del marcador: `@Retry(3)` → `Retry(3)`.
    static func constructor(for marker: AttributeSyntax) -> String {
        let type = marker.attributeName.trimmedDescription
        let arguments = marker.arguments?.trimmedDescription ?? ""
        return "\(type)(\(arguments))"
    }
}

// MARK: - Contexto léxico

enum Enclosing {

    /// Declaración de tipo o extensión que contiene al miembro en expansión, si existe.
    static func group(in context: some MacroExpansionContext) -> (any DeclGroupSyntax)? {
        for syntax in context.lexicalContext {
            if let group = syntax.asProtocol(DeclGroupSyntax.self) { return group }
        }
        return nil
    }

    static func name(of group: any DeclGroupSyntax) -> String {
        if let decl = group.as(StructDeclSyntax.self) { return decl.name.text }
        if let decl = group.as(ClassDeclSyntax.self) { return decl.name.text }
        if let decl = group.as(ActorDeclSyntax.self) { return decl.name.text }
        if let decl = group.as(EnumDeclSyntax.self) { return decl.name.text }
        if let decl = group.as(ProtocolDeclSyntax.self) { return decl.name.text }
        if let decl = group.as(ExtensionDeclSyntax.self) { return decl.extendedType.trimmedDescription }
        return "<unknown>"
    }

    static func typeName(in context: some MacroExpansionContext) -> String {
        group(in: context).map(name(of:)) ?? "<unknown>"
    }
}

// MARK: - Forma de una propiedad decorable

struct StoredProperty {
    let name: String
    let type: TypeSyntax?
    let initializer: ExprSyntax?

    /// Valida que la declaración sea una `var` almacenada de instancia con un solo binding.
    /// Devuelve `nil` tras emitir el diagnóstico correspondiente.
    static func validate(
        _ declaration: VariableDeclSyntax,
        in context: some MacroExpansionContext
    ) -> StoredProperty? {
        if declaration.bindingSpecifier.tokenKind == .keyword(.let) {
            context.error(declaration.bindingSpecifier, id: "let",
                          "decorators cannot be applied to a 'let' constant; use 'var'")
            return nil
        }
        for modifier in declaration.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.static), .keyword(.class), .keyword(.lazy):
                context.error(modifier, id: "modifier",
                              "decorators cannot be applied to a '\(modifier.name.text)' property")
                return nil
            default:
                continue
            }
        }
        guard declaration.bindings.count == 1, let binding = declaration.bindings.first else {
            context.error(declaration.bindings, id: "bindings",
                          "decorators require a single property per declaration")
            return nil
        }
        guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            context.error(binding.pattern, id: "pattern",
                          "decorators require a simple property name")
            return nil
        }
        if binding.accessorBlock != nil {
            context.error(binding, id: "computed",
                          "decorators can only be applied to stored properties")
            return nil
        }
        return StoredProperty(name: name, type: binding.typeAnnotation?.type, initializer: binding.initializer?.value)
    }
}
