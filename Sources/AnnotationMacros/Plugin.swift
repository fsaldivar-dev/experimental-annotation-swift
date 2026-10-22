//
//  Plugin.swift
//  AnnotationMacros
//
//  Un único plugin genérico. Las anotaciones concretas (`@Logged`, `@Retry`, …) no viven aquí:
//  son tipos del usuario registrados con `MarkerMacro`.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AnnotationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DecorableMacro.self,
        MarkerMacro.self,
        DecorateMacro.self,
        AnnotationMacro.self,
        DecoratedFunctionMacro.self,
        DecoratedPropertyMacro.self,
    ]
}
