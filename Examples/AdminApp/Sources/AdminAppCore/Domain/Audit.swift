import Foundation

public struct AuditEntry: Identifiable, Sendable, Equatable {
    public enum Outcome: Sendable, Equatable {
        case allowed
        case denied(String)
    }

    public let id = UUID()
    public let date: Date
    public let user: String
    public let action: String
    public let outcome: Outcome

    public var isDenied: Bool {
        if case .denied = outcome { return true }
        return false
    }
}

public struct ReportRow: Identifiable, Sendable, Equatable {
    public let id: Int
    public let product: String
    public let amount: Int
}
