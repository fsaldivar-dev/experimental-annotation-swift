import AnnotationSwift
import Foundation

struct Clamped<Value: Comparable>: PropertyDecorator {
    let range: ClosedRange<Value>
    init(_ range: ClosedRange<Value>) { self.range = range }

    func decorate(_ value: Value, _ property: Property, next: (Value) -> Value) -> Value {
        next(min(max(value, range.lowerBound), range.upperBound))
    }
}

struct Trimmed: PropertyDecorator {
    func decorate(_ value: String, _ property: Property, next: (String) -> String) -> String {
        next(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct Lowercased: PropertyDecorator {
    func decorate(_ value: String, _ property: Property, next: (String) -> String) -> String {
        next(value.lowercased())
    }
}

@attached(peer) macro Clamped<Bound: Comparable>(_ range: ClosedRange<Bound>) = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Trimmed() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
@attached(peer) macro Lowercased() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
