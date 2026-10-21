import AnnotationSwift

/// Guardián cuya comprobación corre en el main actor, donde vive `Env.state`.
///
/// `GuardDecorator.check` es nonisolated; este protocolo intermedio hace el salto una sola vez
/// para que cada guardián de la app escriba solo `verify`. `Call` no es `Sendable` (lleva los
/// argumentos reales), así que al cruzar al main actor solo pasa el nombre de la acción.
protocol UIGuard: GuardDecorator, Sendable {
    @MainActor func verify(action: String) throws
}

extension UIGuard {
    func check(_ call: Call) throws {
        let action = call.function
        try MainActor.assumeIsolated { try verify(action: action) }
    }
}
