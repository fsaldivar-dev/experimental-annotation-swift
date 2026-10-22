import SwiftUI

struct LoginView: View {
    let coordinator: AppCoordinator
    let reason: LoginReason?

    @State private var user = "viewer"
    @State private var password = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Administración").font(.largeTitle.bold())

            if let message = reasonMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            Form {
                TextField("Usuario", text: $user)
                SecureField("Contraseña", text: $password)
            }
            .formStyle(.grouped)
            .frame(maxWidth: 360)

            if let error {
                Text(error).foregroundStyle(.red)
            }

            Button("Entrar") {
                do {
                    try coordinator.login(user: user, password: password)
                    error = nil
                } catch {
                    self.error = "\(error)"
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

            Text("Usuarios de prueba: admin / editor / viewer (la contraseña es el mismo nombre)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }

    private var reasonMessage: String? {
        switch reason {
        case .expired: "Tu sesión expiró. Vuelve a entrar."
        case .notLoggedIn: "Necesitas iniciar sesión para continuar."
        case .loggedOut: "Sesión cerrada."
        case nil: nil
        }
    }
}
