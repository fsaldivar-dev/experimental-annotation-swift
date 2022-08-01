//
//  LowCaseAnnotation.swift
//  experimental_annotation
//
//  Created by Francisco Javier Saldivar Rubio on 31/07/21.
//

import Foundation

@propertyWrapper
class LowCase<Value: StringProtocol>: ASAnnotation {
    private var value: Value?
    init(wrappedValue value: Value? = nil) {
        self.wrappedValue = value
    }
    public var wrappedValue: Value? {
        get { return self.value }
        set { self.value = self.tranformValue(wrappedValue: newValue) }
    }
    func updateValue<T>(value: T) {
        guard let value = value as? Value else {
            return
        }
        self.wrappedValue = value
    }
    
    func tranformValue<T>(wrappedValue: T?) -> T? {
        guard let stringValue = wrappedValue as? Value else {
            return wrappedValue
        }
        return stringValue.lowercased() as? T
    }
}
