//
//  FpToStringTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class FpToStringTests: XCTestCase {
    func testFloatToString() {
        let result = fpToString(3.14, precision: 3)
        XCTAssertTrue(result.contains("3.14"))
    }

    func testDoubleToString() {
        let result = fpToString(3.14159265358979, precision: 6)
        XCTAssertTrue(result.contains("3.14159"))
    }

    func testZeroToString() {
        let result = fpToString(0.0)
        XCTAssertEqual(result, "0.0")
    }

    func testNegativeToString() {
        let result = fpToString(-1.5)
        XCTAssertTrue(result.contains("-1.5"))
    }
}
