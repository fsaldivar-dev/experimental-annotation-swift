import Foundation
import Observation

/// Estado observable de la app. Los decoradores lo consultan y lo modifican a través de `Env`.
@MainActor
@Observable
public final class AppState {
    public var session: Session? {
        didSet { if let user = session?.user { lastUser = user } }
    }
    /// Último usuario con sesión, para auditar acciones que ocurren justo al expirar.
    public private(set) var lastUser: String?
    public var route: Route = .login(nil)
    public var audit: [AuditEntry] = []
    public var preferences = ReportPreferences()
    public var lastReportLoad: Duration?
    public var lastExport: URL?

    /// Duración de la sesión. Corta a propósito para que la expiración se vea en la demo.
    public var sessionLifetime: TimeInterval = 90

    public init() {}

    public func record(_ action: String, outcome: AuditEntry.Outcome) {
        audit.insert(AuditEntry(date: .now, user: session?.user ?? lastUser ?? "—", action: action, outcome: outcome), at: 0)
    }
}

/// El entorno que ven los decoradores. No reciben `self`, igual que una anotación de Java:
/// hablan con el estado de la app, no con el objeto decorado.
@MainActor
public enum Env {
    public static var state = AppState()
}
