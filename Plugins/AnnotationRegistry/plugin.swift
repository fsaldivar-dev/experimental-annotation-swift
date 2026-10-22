//
//  plugin.swift
//  AnnotationRegistry
//
//  Build-tool plugin: antes de compilar un módulo, genera las declaraciones de macro marcador
//  para sus tipos `@Annotation`, de modo que `@Logged` se pueda escribir sin registrar nada a mano.
//
//  Actívalo por target:
//      .target(name: "App", dependencies: [...],
//              plugins: [.plugin(name: "AnnotationRegistry", package: "experimental-annotation-swift")])
//

import Foundation
import PackagePlugin

@main
struct AnnotationRegistry: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SwiftSourceModuleTarget else { return [] }
        let inputs = target.sourceFiles(withSuffix: "swift").map(\.url)
        return [try command(tool: context.tool(named: "annotation-registry").url,
                            workDirectory: context.pluginWorkDirectoryURL,
                            targetName: target.name, inputs: inputs)]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension AnnotationRegistry: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let inputs = target.inputFiles.filter { $0.url.pathExtension == "swift" }.map(\.url)
        return [try command(tool: context.tool(named: "annotation-registry").url,
                            workDirectory: context.pluginWorkDirectoryURL,
                            targetName: target.displayName, inputs: inputs)]
    }
}
#endif

private func command(tool: URL, workDirectory: URL, targetName: String, inputs: [URL]) throws -> Command {
    let output = workDirectory.appending(path: "Annotations+Registry.swift")
    return .buildCommand(
        displayName: "AnnotationSwift: registrar anotaciones de \(targetName)",
        executable: tool,
        arguments: [output.path()] + inputs.map { $0.path() },
        inputFiles: inputs,
        outputFiles: [output]
    )
}
