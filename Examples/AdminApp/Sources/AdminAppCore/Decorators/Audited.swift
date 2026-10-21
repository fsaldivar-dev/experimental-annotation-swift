import AnnotationSwift

/// Deja rastro de cada acción: quién, qué y si pasó. Va *primero* en la pila para que vea
/// también los rechazos de los guardianes que están debajo.
struct Audited: HookDecorator {
    func didReturn(_ call: Call, result: Any) {
        let action = call.function
        MainActor.assumeIsolated { Env.state.record(action, outcome: .allowed) }
    }
    func didThrow(_ call: Call, error: any Error) {
        let action = call.function, reason = "\(error)"
        MainActor.assumeIsolated { Env.state.record(action, outcome: .denied(reason)) }
    }
}

@attached(peer) macro Audited() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
