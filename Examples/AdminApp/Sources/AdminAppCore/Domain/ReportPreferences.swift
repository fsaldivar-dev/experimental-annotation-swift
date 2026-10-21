import AnnotationSwift

/// Preferencias del módulo de reportes. Las propiedades decoradas normalizan cualquier
/// entrada del usuario antes de guardarla.
@Decorable
public struct ReportPreferences {
    @Clamped(5...100)
    public var pageSize: Int = 25

    @Trimmed
    @Lowercased
    public var filter: String = ""

    public init() {}
}
