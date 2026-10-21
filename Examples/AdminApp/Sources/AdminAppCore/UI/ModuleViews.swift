import SwiftUI

struct InventoryView: View {
    var body: some View {
        List(Catalog.rows.prefix(20)) { row in
            HStack {
                Text(row.product)
                Spacer()
                Text("\(row.amount) uds").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Inventario")
    }
}

struct ReportsView: View {
    let coordinator: AppCoordinator
    @State private var rows: [ReportRow] = []
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        @Bindable var state = Env.state
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Filtro (se recorta y pasa a minúsculas)", text: $state.preferences.filter)
                    .textFieldStyle(.roundedBorder)
                Stepper("Página: \(state.preferences.pageSize)", value: $state.preferences.pageSize, in: 0...200, step: 5)
                Button(loading ? "Cargando…" : "Cargar") { load() }
                    .disabled(loading)
            }
            Text("Filtro aplicado: '\(state.preferences.filter)' · tamaño acotado a 5…100 por @Clamped")
                .font(.caption).foregroundStyle(.secondary)
            if let duration = state.lastReportLoad {
                Text("Última carga: \(duration.formatted(.units(allowed: [.milliseconds]))) (medido por @Measured)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let error { Text(error).foregroundStyle(.red) }
            List(rows) { row in
                HStack { Text(row.product); Spacer(); Text("$\(row.amount)") }
            }
        }
        .padding()
        .navigationTitle("Reportes")
    }

    private func load() {
        loading = true
        Task {
            defer { loading = false }
            do {
                rows = try await coordinator.loadReports()
                error = nil
            } catch {
                self.error = "\(error)"
            }
        }
    }
}

struct UsersView: View {
    var body: some View {
        List(Directory.accounts.sorted(by: { $0.key < $1.key }), id: \.key) { user, roles in
            HStack {
                Label(user, systemImage: "person")
                Spacer()
                Text(roles.map(\.rawValue).sorted().joined(separator: ", ")).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Usuarios")
    }
}

struct AuditView: View {
    let coordinator: AppCoordinator
    @State private var message: String?

    var body: some View {
        let state = Env.state
        VStack(alignment: .leading) {
            HStack {
                Button("Exportar CSV (requiere Reportes y Usuarios)") {
                    Task {
                        do { message = "Exportado en \(try await coordinator.exportAudit().path)" }
                        catch { message = "\(error)" }
                    }
                }
                if let message { Text(message).font(.caption).textSelection(.enabled) }
            }
            .padding([.horizontal, .top])
            List(state.audit) { entry in
                HStack {
                    Image(systemName: entry.isDenied ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(entry.isDenied ? .red : .green)
                    Text(entry.date, style: .time).monospacedDigit().foregroundStyle(.secondary)
                    Text(entry.user).bold()
                    Text(entry.action)
                    Spacer()
                    if case .denied(let reason) = entry.outcome {
                        Text(reason).foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Auditoría")
    }
}

struct ForbiddenView: View {
    let coordinator: AppCoordinator
    let module: Module

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill").font(.system(size: 48)).foregroundStyle(.red)
            Text("Sin permiso").font(.largeTitle.bold())
            Text("Tu rol no puede entrar a \(module.title). Lo decidió @Guard(access: .\(module.rawValue)).")
                .foregroundStyle(.secondary)
            Button("Volver al inventario") { try? coordinator.openInventory() }
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
}
