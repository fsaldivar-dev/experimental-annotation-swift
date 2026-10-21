import AnnotationSwift

/// El rol de la sesión tiene acceso a *todos* los módulos indicados. Si no, pantalla de
/// "sin permiso" y el cuerpo nunca corre. Va después de `@Authenticated`.
struct Guard: UIGuard {
    let modules: [Module]
    init(access modules: Module...) { self.modules = modules }

    func verify(action: String) throws {
        guard let session = Env.state.session else { throw GuardError.notLoggedIn }
        if let denied = modules.first(where: { !session.canAccess($0) }) {
            Env.state.route = .forbidden(denied)
            throw GuardError.forbidden(denied)
        }
    }
}

@attached(peer) macro Guard(access: Module...) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
