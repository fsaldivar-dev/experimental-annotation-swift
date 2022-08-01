//
//  TestGroup.swift
//  Tests
//
//  Created by Francisco Javier Saldivar Rubio on 31/07/21.
//

import XCTest
@testable import AnnotationSwift
struct Mock2Model {
    @ASGroup(Email<String>(),
              LowCase<String>())
    var email: String?
    @ASGroup(MinLength<String>(minLength: 3),
              MaxLength<String>(maxLength: 10))
    var min3Max10: String?
}

final class TestGroup: XCTestCase {
    func testEmail() {
        let mock = Mock2Model()
        mock.email = "FSALDIVAR.DEV@GMAIL.com"
        XCTAssertNotEqual(mock.email, "FSALDIVAR.DEV@GMAIL.com")
        XCTAssertEqual(mock.email, "fsaldivar.dev@gmail.com")
        mock.email = "fsaldivar/.@DEVGMAIL.com"
        XCTAssertNil(mock.email)
        mock.email = "fsaldivar.dev@GMAIL.com-"
        XCTAssertNil(mock.email)
    }
    func testLenght() {
        let mock = Mock2Model()
        mock.min3Max10 = "ab"
        XCTAssertNil(mock.min3Max10)
        mock.min3Max10 = "123456789123"
        XCTAssertNil(mock.min3Max10)
        mock.min3Max10 = "abc"
        XCTAssertTrue(mock.min3Max10 == "abc")
        mock.min3Max10 = "1234567891"
        XCTAssertTrue(mock.min3Max10 == "1234567891")
        mock.min3Max10 = "123456789"
        XCTAssertTrue(mock.min3Max10 == "123456789")
        mock.min3Max10 = "12345678"
        XCTAssertTrue(mock.min3Max10 == "12345678")
        mock.min3Max10 = "1234567"
        XCTAssertTrue(mock.min3Max10 == "1234567")
        mock.min3Max10 = "123456"
        XCTAssertTrue(mock.min3Max10 == "123456")
        mock.min3Max10 = "12345"
        XCTAssertTrue(mock.min3Max10 == "12345")
        mock.min3Max10 = "1234"
        XCTAssertTrue(mock.min3Max10 == "1234")
    }

}
