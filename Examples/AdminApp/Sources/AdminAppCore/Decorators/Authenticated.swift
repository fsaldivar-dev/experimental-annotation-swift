import AnnotationSwift
import Foundation

/// Hay sesión y no ha expirado. Si no, redirige al login con el motivo y detiene el cuerpo.
struct Authenticated: UIGuard {
    func verify(action: String) throws {
        guard let session = Env.state.session else {
            Env.state.route = .login(.notLoggedIn)
            throw GuardError.notLoggedIn
        }
        guard !session.isExpired else {
            Env.state.session = nil
            Env.state.route = .login(.expired)
            throw GuardError.sessionExpired
        }
    }
}

@attached(peer) macro Authenticated() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
