//
//  EncodingTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class EncodingTests: XCTestCase {
    func testUtf8BasicParsing() throws {
        let node = try YAML.load("hello")
        XCTAssertEqual(node.scalar, "hello")
    }

    func testUtf8WithBOM() throws {
        let bom = "\u{FEFF}"
        let node = try YAML.load(bom + "hello")
        XCTAssertEqual(node.scalar, "hello")
    }

    func testUnicodeScalar() throws {
        let node = try YAML.load("\"\\u0041\"")  // 'A'
        XCTAssertEqual(node.scalar, "A")
    }

    func testUnicodeString() throws {
        let node = try YAML.load("こんにちは")
        XCTAssertEqual(node.scalar, "こんにちは")
    }
}
