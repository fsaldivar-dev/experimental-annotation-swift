import SwiftUI

/// Punto de entrada de la UI. Cambia de pantalla según la ruta, como un router.
public struct AdminRootView: View {
    @State private var coordinator = AppCoordinator()

    public init() {}

    public var body: some View {
        let state = Env.state
        Group {
            switch state.route {
            case .login(let reason):
                LoginView(coordinator: coordinator, reason: reason)
            case .forbidden(let module):
                ForbiddenView(coordinator: coordinator, module: module)
            case .module(let module):
                ShellView(coordinator: coordinator, selected: module)
            }
        }
        .frame(minWidth: 820, minHeight: 540)
    }
}
