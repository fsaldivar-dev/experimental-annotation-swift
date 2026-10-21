import AnnotationSwift
import Foundation

/// Lo único decorado de la app. Las vistas llaman a estos métodos y reaccionan a `Env.state.route`,
/// exactamente como un router web con sus guardias.
///
/// Orden de la pila, de afuera hacia adentro:
/// 1. `@Audited` registra todo, incluidos los rechazos de los guardianes de abajo.
/// 2. `@Authenticated` exige sesión viva; si no, redirige al login.
/// 3. `@Guard(access:)` exige rol; si no, redirige a "sin permiso".
/// 4. `@RefreshesSession` renueva la sesión solo si el cuerpo terminó bien.
@Decorable
@MainActor
public final class AppCoordinator {

    public init() {}

    // MARK: Sesión

    @Audited
    public func login(user: String, password: String) throws {
        let roles = try Directory.authenticate(user: user, password: password)
        Env.state.session = Session(user: user, roles: roles, expiresAt: .now + Env.state.sessionLifetime)
        Env.state.route = .module(.inventory)
    }

    @Audited
    public func logout() {
        Env.state.session = nil
        Env.state.route = .login(.loggedOut)
    }

    /// Qué módulos mostrar en el menú. Misma política que `@Guard`, sin duplicarla.
    public var visibleModules: [Module] {
        guard let session = Env.state.session else { return [] }
        return Module.allCases.filter(session.canAccess)
    }

    /// Solo para la demo: caduca la sesión al instante.
    public func simulateExpiry() {
        Env.state.session?.expiresAt = .now - 1
    }

    // MARK: Navegación protegida

    @Audited
    @Authenticated
    @Guard(access: .inventory)
    @RefreshesSession
    public func openInventory() throws {
        Env.state.route = .module(.inventory)
    }

    @Audited
    @Authenticated
    @Guard(access: .reports)
    @RefreshesSession
    public func openReports() throws {
        Env.state.route = .module(.reports)
    }

    @Audited
    @Authenticated
    @Guard(access: .users)
    @RefreshesSession
    public func openUsers() throws {
        Env.state.route = .module(.users)
    }

    // MARK: Acciones de módulo

    @Audited
    @Authenticated
    @Guard(access: .reports)
    @RefreshesSession
    @Measured
    public func loadReports() async throws -> [ReportRow] {
        try await Task.sleep(for: .milliseconds(300))
        let preferences = Env.state.preferences
        return Catalog.rows
            .filter { preferences.filter.isEmpty || $0.product.lowercased().contains(preferences.filter) }
            .prefix(preferences.pageSize)
            .map { $0 }
    }

    /// Acción transversal: exige acceso a dos módulos a la vez.
    @Audited
    @Authenticated
    @Guard(access: .reports, .users)
    @RefreshesSession
    public func exportAudit() async throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("audit-\(Int(Date.now.timeIntervalSince1970)).csv")
        let lines = ["fecha,usuario,accion,resultado"] + Env.state.audit.map { entry in
            let outcome = switch entry.outcome {
            case .allowed: "ok"
            case .denied(let reason): reason
            }
            return "\(entry.date.ISO8601Format()),\(entry.user),\(entry.action),\(outcome)"
        }
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        Env.state.lastExport = url
        return url
    }
}

enum Catalog {
    static let rows: [ReportRow] = (1...120).map { index in
        let products = ["Tornillo", "Tuerca", "Arandela", "Perno", "Clavo", "Remache"]
        return ReportRow(id: index, product: "\(products[index % products.count]) \(index)", amount: (index * 37) % 500)
    }
}
