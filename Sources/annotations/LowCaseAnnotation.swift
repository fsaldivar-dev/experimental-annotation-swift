//
//  LowCaseAnnotation.swift
//  experimental_annotation
//
//  Created by Francisco Javier Saldivar Rubio on 31/07/21.
//

import Foundation

@propertyWrapper
public struct LowCase<Value: StringProtocol>: ASAnnotationWrapped {
    
    private var value: Value?
    
    public init(wrappedValue value: Value? = nil) {
        self.wrappedValue = value
    }
    
    public var wrappedValue: Value? {
        get { return self.value }
        set { self.value = self.tranformValue(wrappedValue: newValue) }
    }
    
    public func tranformValue<T>(wrappedValue: T?) -> T? {
        guard let stringValue = wrappedValue as? Value else {
            return wrappedValue
        }
        return stringValue.lowercased() as? T
    }
}
