/// Cada sección de la app. La política de acceso vive aquí y la usan tanto el menú
/// (qué mostrar) como el guardián `@Guard` (qué permitir), así nunca se desincronizan.
public enum Module: String, CaseIterable, Sendable, Identifiable {
    case inventory, reports, users

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .inventory: "Inventario"
        case .reports: "Reportes"
        case .users: "Usuarios"
        }
    }

    public var icon: String {
        switch self {
        case .inventory: "shippingbox"
        case .reports: "chart.bar"
        case .users: "person.2"
        }
    }

    public var allowedRoles: Set<Role> {
        switch self {
        case .inventory: [.admin, .editor, .viewer]
        case .reports: [.admin, .editor]
        case .users: [.admin]
        }
    }
}
