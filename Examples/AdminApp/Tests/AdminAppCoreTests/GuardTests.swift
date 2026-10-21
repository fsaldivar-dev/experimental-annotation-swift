import Foundation
import Testing
@testable import AdminAppCore

/// Los guardianes se prueban contra el coordinador real, sin UI: la ruta es el "navigator".
@MainActor
@Suite("Guardianes de navegación", .serialized)
struct GuardTests {

    let coordinator: AppCoordinator

    init() {
        Env.state = AppState()
        coordinator = AppCoordinator()
    }

    @Test("Credenciales inválidas: no hay sesión y queda auditado")
    func invalidLogin() {
        #expect(throws: GuardError.invalidCredentials) { try coordinator.login(user: "admin", password: "x") }
        #expect(Env.state.session == nil)
        #expect(Env.state.route == .login(nil))
        #expect(Env.state.audit.first?.isDenied == true)
    }

    @Test("Al entrar, el menú muestra solo los módulos del rol")
    func visibleModules() throws {
        try coordinator.login(user: "viewer", password: "viewer")
        #expect(Env.state.route == .module(.inventory))
        #expect(coordinator.visibleModules == [.inventory])

        try coordinator.login(user: "editor", password: "editor")
        #expect(coordinator.visibleModules == [.inventory, .reports])

        try coordinator.login(user: "admin", password: "admin")
        #expect(coordinator.visibleModules == Module.allCases)
    }

    @Test("Sin sesión, cualquier navegación redirige al login")
    func notLoggedIn() {
        #expect(throws: GuardError.notLoggedIn) { try coordinator.openInventory() }
        #expect(Env.state.route == .login(.notLoggedIn))
    }

    @Test("Un viewer que fuerza Usuarios va a 'sin permiso' y queda auditado")
    func forbidden() throws {
        try coordinator.login(user: "viewer", password: "viewer")
        #expect(throws: GuardError.forbidden(.users)) { try coordinator.openUsers() }
        #expect(Env.state.route == .forbidden(.users))
        let entry = try #require(Env.state.audit.first)
        #expect(entry.action == "openUsers()")
        #expect(entry.outcome == .denied("sin permiso para Usuarios"))
    }

    @Test("Sesión expirada: redirige al login con motivo y borra la sesión")
    func expired() throws {
        try coordinator.login(user: "admin", password: "admin")
        coordinator.simulateExpiry()
        #expect(throws: GuardError.sessionExpired) { try coordinator.openUsers() }
        #expect(Env.state.session == nil)
        #expect(Env.state.route == .login(.expired))
        // La auditoría conserva quién era aunque la sesión ya se haya borrado.
        #expect(Env.state.audit.first?.user == "admin")
        #expect(Env.state.audit.first?.outcome == .denied("sesión expirada"))
    }

    @Test("Cada acción permitida renueva la sesión (sesión deslizante)")
    func slidingSession() throws {
        try coordinator.login(user: "editor", password: "editor")
        Env.state.session?.expiresAt = .now + 5
        try coordinator.openReports()
        let remaining = try #require(Env.state.session?.remaining)
        #expect(remaining > 60)
    }

    @Test("Una acción rechazada no renueva la sesión")
    func deniedDoesNotRefresh() throws {
        try coordinator.login(user: "viewer", password: "viewer")
        Env.state.session?.expiresAt = .now + 5
        #expect(throws: GuardError.forbidden(.users)) { try coordinator.openUsers() }
        let remaining = try #require(Env.state.session?.remaining)
        #expect(remaining <= 5)
    }

    @Test("Exportar exige acceso a Reportes y Usuarios a la vez")
    func exportRequiresBothModules() async throws {
        try coordinator.login(user: "editor", password: "editor")
        await #expect(throws: GuardError.forbidden(.users)) { try await coordinator.exportAudit() }

        try coordinator.login(user: "admin", password: "admin")
        let url = try await coordinator.exportAudit()
        #expect(FileManager.default.fileExists(atPath: url.path))
        let csv = try String(contentsOf: url, encoding: .utf8)
        #expect(csv.hasPrefix("fecha,usuario,accion,resultado"))
    }

    @Test("Cargar reportes se mide y respeta las preferencias decoradas")
    func reports() async throws {
        try coordinator.login(user: "editor", password: "editor")
        Env.state.preferences.pageSize = 500      // @Clamped → 100
        Env.state.preferences.filter = "  TORNILLO "  // @Trimmed @Lowercased → "tornillo"
        #expect(Env.state.preferences.pageSize == 100)
        #expect(Env.state.preferences.filter == "tornillo")

        let rows = try await coordinator.loadReports()
        #expect(!rows.isEmpty)
        #expect(rows.allSatisfy { $0.product.hasPrefix("Tornillo") })
        let duration = try #require(Env.state.lastReportLoad)
        #expect(duration >= .milliseconds(300))
    }

    @Test("Cerrar sesión vuelve al login y el menú queda vacío")
    func logout() throws {
        try coordinator.login(user: "admin", password: "admin")
        coordinator.logout()
        #expect(Env.state.route == .login(.loggedOut))
        #expect(coordinator.visibleModules.isEmpty)
    }
}
