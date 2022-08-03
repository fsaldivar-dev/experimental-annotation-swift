//
//  Tests.swift
//  Tests
//
//  Created by Francisco Javier Saldivar Rubio on 31/07/21.
//

import XCTest
@testable import AnnotationSwift

struct MockModel {
    @Email
    var email: String?
    @MaxLength(maxLength: 10)
    var wordMax10: String?
    @MinLength(minLength: 10)
    var wordMin10: String?
}

final class TestAnnotation: XCTestCase {

    func testEmailSuccess() {
        var mockModel = MockModel()
        mockModel.email = "fsaldivar.dev@gmail.com"
        XCTAssert(mockModel.email == "fsaldivar.dev@gmail.com")
        mockModel.email = "fsaldivar.dev@hotmail.com"
        XCTAssert(mockModel.email == "fsaldivar.dev@hotmail.com")
        mockModel.email = "fsaldivar.dev@yahoo.com.mx"
        XCTAssert(mockModel.email == "fsaldivar.dev@yahoo.com.mx")
        mockModel.email = "fsaldivar_dev@yahoo.com.mx"
        XCTAssert(mockModel.email == "fsaldivar_dev@yahoo.com.mx")
        mockModel.email = "fsaldivar-dev@yahoo.com.mx"
        XCTAssert(mockModel.email == "fsaldivar-dev@yahoo.com.mx")
    }

    func testEmailError() {
        var mockModel = MockModel()
        mockModel.email = "fsaldivar dev@gmail.com"
        XCTAssertNil(mockModel.email)
        mockModel.email = "@fsaldivar.dev@hotmail.com"
        XCTAssertNil(mockModel.email)
        mockModel.email = "fsaldivar.dev@yahoo_com.mx"
        XCTAssertNil(mockModel.email)
        mockModel.email = "fsaldivar_dev@yahoo/com.mx"
        XCTAssertNil(mockModel.email)
        mockModel.email = "fsaldivar-dev/yahoo.com.mx"
        XCTAssertNil(mockModel.email)
    }

    func testMax() {
        let word13 = "1234567891123"
        let spectedString = "1234567891"
        var mockModel = MockModel()
        mockModel.wordMax10 = word13
        XCTAssertNil(mockModel.wordMax10)
        mockModel.wordMax10 = spectedString
        XCTAssert(mockModel.wordMax10 == spectedString)
    }

    func testMin() {
        let spectedString = "1234567891123"
        let word9  = "123456789"
        var mockModel = MockModel()
        mockModel.wordMin10 = word9
        XCTAssertNil(mockModel.wordMin10)
        mockModel.wordMin10 = spectedString
        XCTAssert(mockModel.wordMin10 == spectedString)
    }
}
