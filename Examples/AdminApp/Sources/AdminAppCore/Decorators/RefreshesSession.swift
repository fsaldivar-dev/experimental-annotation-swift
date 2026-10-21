import AnnotationSwift
import Foundation

/// Sesión deslizante, como en la web: cada acción protegida que termina bien renueva la expiración.
struct RefreshesSession: HookDecorator {
    func didReturn(_ call: Call, result: Any) {
        MainActor.assumeIsolated {
            Env.state.session?.expiresAt = .now + Env.state.sessionLifetime
        }
    }
}

@attached(peer) macro RefreshesSession() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
