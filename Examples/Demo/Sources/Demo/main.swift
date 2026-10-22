//
//  main.swift
//  Demo
//

import AnnotationSwift
import Foundation

struct NetworkDown: Error {}

@Decorable
struct Service {
    var attempts = 0

    @Logged
    @Retry(3)
    @Measured
    mutating func fetch(id: Int) async throws -> String {
        attempts += 1
        try await Task.sleep(for: .milliseconds(20))
        guard attempts >= 3 else { throw NetworkDown() }
        return "payload-\(id)"
    }

    @Logged
    func greet(_ name: String) -> String { "hola, \(name)" }

    /// Misma cadena que `fetch`, sin usar marcadores: los decoradores van como valores.
    /// Útil cuando no quieres declarar `@attached(peer) macro …` por cada decorador.
    @Decorate(Logged(), Measured())
    func ping() async throws -> String {
        try await Task.sleep(for: .milliseconds(10))
        return "pong"
    }
}

@Decorable
struct User {
    @Trimmed
    @Lowercased
    var email: String
}

func run() async throws {
    var service = Service()
    print(service.greet("Paco"))
    print()
    print(try await service.fetch(id: 7))
    print()
    print(try await service.ping())
    print()
    var user = User(email: "  PACO@Mail.com  ")
    print("email normalizado: '\(user.email)'")
    user.email = "  OTRO@MAIL.COM "
    print("email reasignado:  '\(user.email)'")
}

try await run()
