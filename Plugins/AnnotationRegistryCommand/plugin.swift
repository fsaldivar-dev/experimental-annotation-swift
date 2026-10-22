//
//  plugin.swift
//  AnnotationRegistryCommand
//
//  Command plugin: genera `AnnotationRegistry.generated.swift` dentro de cada target con tipos
//  `@Annotation`, para commitearlo como fuente normal. Cero costo en build: el generador corre solo
//  cuando tú lo pides.
//
//      swift package --allow-writing-to-package-directory annotation-registry            # escribe
//      swift package --allow-writing-to-package-directory annotation-registry --check     # CI: falla si está desactualizado
//      (--check no escribe, pero SwiftPM exige el permiso declarado por el plugin en modo no interactivo)
//      swift package --allow-writing-to-package-directory annotation-registry --target App
//

import Foundation
import PackagePlugin

@main
struct AnnotationRegistryCommand: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let options = Options(arguments)
        let targets = context.package.targets
            .compactMap { $0 as? SwiftSourceModuleTarget }
            .filter { options.targets.isEmpty || options.targets.contains($0.name) }
        try run(tool: try context.tool(named: "annotation-registry").url,
                workDirectory: context.pluginWorkDirectoryURL,
                targets: targets.map { ($0.name, $0.directoryURL, $0.sourceFiles(withSuffix: "swift").map(\.url)) },
                options: options)
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension AnnotationRegistryCommand: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        let options = Options(arguments)
        let targets = context.xcodeProject.targets
            .filter { options.targets.isEmpty || options.targets.contains($0.displayName) }
            .map { target -> (String, URL, [URL]) in
                let sources = target.inputFiles.filter { $0.url.pathExtension == "swift" }.map(\.url)
                let directory = sources.first?.deletingLastPathComponent() ?? context.xcodeProject.directoryURL
                return (target.displayName, directory, sources)
            }
        try run(tool: try context.tool(named: "annotation-registry").url,
                workDirectory: context.pluginWorkDirectoryURL, targets: targets, options: options)
    }
}
#endif

struct Options {
    var targets: Set<String> = []
    var check = false
    init(_ arguments: [String]) {
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--check": check = true
            case "--target": if let name = iterator.next() { targets.insert(name) }
            default: break
            }
        }
    }
}

let fileName = "AnnotationRegistry.generated.swift"

struct RegistryError: Error, CustomStringConvertible {
    let description: String
}

private func run(tool: URL, workDirectory: URL, targets: [(name: String, directory: URL, sources: [URL])], options: Options) throws {
    var stale: [String] = []
    for target in targets {
        // El propio registro no es entrada: evita que una ejecución anterior afecte a la siguiente.
        let sources = target.sources.filter { $0.lastPathComponent != fileName }
        let generated = workDirectory.appending(path: "\(target.name)-\(fileName)")
        try generate(tool: tool, output: generated, sources: sources)
        let content = try String(contentsOf: generated, encoding: .utf8)
        let destination = target.directory.appending(path: fileName)
        let hasAnnotations = content.contains("macro ")
        let existing = try? String(contentsOf: destination, encoding: .utf8)

        if options.check {
            if hasAnnotations, existing != content { stale.append(target.name) }
            if !hasAnnotations, existing != nil, existing != content { stale.append(target.name) }
            continue
        }
        if hasAnnotations {
            guard existing != content else { print("= \(target.name)/\(fileName) al día"); continue }
            try content.write(to: destination, atomically: true, encoding: .utf8)
            print("✓ \(target.name)/\(fileName) escrito")
        } else if existing != nil {
            try FileManager.default.removeItem(at: destination)
            print("− \(target.name)/\(fileName) eliminado (ya no hay tipos @Annotation)")
        }
    }
    if !stale.isEmpty {
        throw RegistryError(description: "registro de anotaciones desactualizado en: \(stale.joined(separator: ", ")). Ejecuta `swift package --allow-writing-to-package-directory annotation-registry`.")
    }
    if options.check { print("✓ registros de anotaciones al día") }
}

private func generate(tool: URL, output: URL, sources: [URL]) throws {
    let process = Process()
    process.executableURL = tool
    process.arguments = [output.path()] + sources.map { $0.path() }
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw RegistryError(description: "annotation-registry terminó con código \(process.terminationStatus)") }
}
