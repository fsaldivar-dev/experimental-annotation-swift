import Foundation

public struct Session: Sendable, Equatable {
    public var user: String
    public var roles: Set<Role>
    public var expiresAt: Date

    public init(user: String, roles: Set<Role>, expiresAt: Date) {
        self.user = user
        self.roles = roles
        self.expiresAt = expiresAt
    }

    public var isExpired: Bool { expiresAt <= .now }
    public var remaining: TimeInterval { max(0, expiresAt.timeIntervalSinceNow) }

    public func canAccess(_ module: Module) -> Bool {
        !roles.isDisjoint(with: module.allowedRoles)
    }
}

/// Usuarios de prueba. Usuario y contraseña coinciden con el rol.
public enum Directory {
    public static let accounts: [String: Set<Role>] = [
        "admin": [.admin],
        "editor": [.editor],
        "viewer": [.viewer],
    ]

    public static func authenticate(user: String, password: String) throws -> Set<Role> {
        guard let roles = accounts[user], password == user else { throw GuardError.invalidCredentials }
        return roles
    }
}
