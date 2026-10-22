//
//  main.swift
//  annotation-registry
//
//  Uso: annotation-registry <salida.swift> <fuente1.swift> <fuente2.swift> …
//  Lo invoca el plugin AnnotationRegistry; también sirve a mano para inspeccionar la salida.
//

import AnnotationRegistryCore
import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
guard let outputPath = arguments.first else {
    FileHandle.standardError.write(Data("uso: annotation-registry <salida.swift> <fuentes.swift…>\n".utf8))
    exit(2)
}
var sources: [(path: String, text: String)] = []
for path in arguments.dropFirst() {
    if let text = try? String(contentsOfFile: path, encoding: .utf8) {
        sources.append((path, text))
    }
}
let generated = RegistryGenerator().generate(sources: sources)
do {
    try FileManager.default.createDirectory(atPath: (outputPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    try generated.write(toFile: outputPath, atomically: true, encoding: .utf8)
} catch {
    FileHandle.standardError.write(Data("annotation-registry: no se pudo escribir \(outputPath): \(error)\n".utf8))
    exit(1)
}
