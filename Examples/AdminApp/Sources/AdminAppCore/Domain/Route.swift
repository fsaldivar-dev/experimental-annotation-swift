public enum LoginReason: Sendable, Equatable {
    case notLoggedIn, expired, loggedOut
}

/// Las rutas de la app, como en un router web. Los guardianes redirigen cambiando la ruta.
public enum Route: Sendable, Equatable {
    case login(LoginReason?)
    case module(Module)
    case forbidden(Module)
}

public enum GuardError: Error, Equatable, CustomStringConvertible {
    case invalidCredentials
    case notLoggedIn
    case sessionExpired
    case forbidden(Module)

    public var description: String {
        switch self {
        case .invalidCredentials: "credenciales inválidas"
        case .notLoggedIn: "sin sesión"
        case .sessionExpired: "sesión expirada"
        case .forbidden(let module): "sin permiso para \(module.title)"
        }
    }
}
