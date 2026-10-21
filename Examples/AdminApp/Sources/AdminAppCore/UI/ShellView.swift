import SwiftUI

enum SidebarItem: Hashable {
    case module(Module)
    case audit
}

struct ShellView: View {
    let coordinator: AppCoordinator
    let selected: Module
    @State private var selection: SidebarItem?
    @State private var denied: String?

    var body: some View {
        let state = Env.state
        NavigationSplitView {
            List(selection: $selection) {
                Section("Módulos") {
                    ForEach(coordinator.visibleModules) { module in
                        Label(module.title, systemImage: module.icon).tag(SidebarItem.module(module))
                    }
                }
                Section("Sistema") {
                    Label("Auditoría", systemImage: "list.bullet.clipboard").tag(SidebarItem.audit)
                }
                Section("Probar guardianes") {
                    Button("Forzar acceso a Usuarios") { attempt { try coordinator.openUsers() } }
                    Button("Forzar acceso a Reportes") { attempt { try coordinator.openReports() } }
                    Button("Simular expiración") { coordinator.simulateExpiry() }
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 240)
            .safeAreaInset(edge: .bottom) {
                SessionBanner(coordinator: coordinator)
            }
        } detail: {
            switch selection ?? .module(selected) {
            case .module(.inventory): InventoryView()
            case .module(.reports): ReportsView(coordinator: coordinator)
            case .module(.users): UsersView()
            case .audit: AuditView(coordinator: coordinator)
            }
        }
        .onAppear { selection = .module(selected) }
        .onChange(of: state.route) { _, route in
            if case .module(let module) = route { selection = .module(module) }
        }
        .onChange(of: selection) { _, item in
            guard case .module(let module) = item, module != selected else { return }
            attempt {
                switch module {
                case .inventory: try coordinator.openInventory()
                case .reports: try coordinator.openReports()
                case .users: try coordinator.openUsers()
                }
            }
        }
        .alert("Acción rechazada", isPresented: .init(get: { denied != nil }, set: { if !$0 { denied = nil } })) {
            Button("Entendido") { denied = nil }
        } message: {
            Text(denied ?? "")
        }
    }

    private func attempt(_ action: () throws -> Void) {
        do { try action() } catch { denied = "\(error)" }
    }
}

struct SessionBanner: View {
    let coordinator: AppCoordinator

    var body: some View {
        let state = Env.state
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            VStack(alignment: .leading, spacing: 6) {
                if let session = state.session {
                    Label(session.user, systemImage: "person.crop.circle").font(.headline)
                    Text("Roles: \(session.roles.map(\.rawValue).sorted().joined(separator: ", "))")
                        .font(.caption).foregroundStyle(.secondary)
                    let remaining = Int(session.remaining)
                    Text(remaining > 0 ? "Sesión: \(remaining)s" : "Sesión expirada")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(remaining <= 15 ? .red : .secondary)
                }
                Button("Cerrar sesión") { coordinator.logout() }
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.bar)
        }
    }
}
