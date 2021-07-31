//
//  experimental_annotation.swift
//  experimental_annotation
//
//  Created by Francisco Javier Saldivar Rubio on 31/07/21.
//
public protocol Annotation {
    func executeAction<T>(wrappedValue: T?) -> T?
    func initValue<T>(value: T)
}

public protocol AnnotationGroup {
    func getAnnotationAny<T>(typeOf: T.Type) -> T?
}

@propertyWrapper
public class GroupSet<SetValue>: AnnotationGroup {
    fileprivate var service: SetValue?
    fileprivate var annotations: [Annotation]
    public init(_ annotations: Annotation ...) {
        self.annotations = annotations
    }

    public var wrappedValue: SetValue? {
        get { self.service}
        set {
            var updateValue = newValue
            self.annotations.forEach({updateValue = $0.executeAction(wrappedValue: updateValue)})
            self.annotations.forEach({ $0.initValue(value: updateValue)})
            self.service = updateValue
        }
    }
    
    public func getAnnotationAny<T>(typeOf: T.Type) -> T? {
        return self.annotations.first(where: { $0 is T}) as? T
    }
}
