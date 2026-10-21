import AnnotationSwift

/// Mide la duración y la publica en el estado para que la UI la muestre.
struct Measured: Decorator {
    func decorate<Out>(_ call: Call, _ next: () throws -> Out) rethrows -> Out {
        let start = ContinuousClock.now
        defer { publish(ContinuousClock.now - start) }
        return try next()
    }

    func decorate<Out>(_ call: Call, isolation: isolated (any Actor)?, _ next: () async throws -> Out) async rethrows -> Out {
        let start = ContinuousClock.now
        defer { publish(ContinuousClock.now - start) }
        return try await next()
    }

    private func publish(_ duration: Duration) {
        MainActor.assumeIsolated { Env.state.lastReportLoad = duration }
    }
}

@attached(peer) macro Measured() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
