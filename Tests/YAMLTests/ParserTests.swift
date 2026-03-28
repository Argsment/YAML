//
//  ParserTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class ParserTests: XCTestCase {
    func testEmptyString() throws {
        let node = try YAML.load("")
        XCTAssertTrue(!node.isDefined || node.isNull)
    }

    func testScalarString() throws {
        let node = try YAML.load("hello")
        XCTAssertEqual(node.scalar, "hello")
    }

    func testBasicMap() throws {
        let node = try YAML.load("key: value")
        XCTAssertEqual(node["key"].scalar, "value")
    }

    func testBasicSequence() throws {
        let yaml = """
        - a
        - b
        - c
        """
        let node = try YAML.load(yaml)
        XCTAssertEqual(node.size, 3)
    }

    func testNestedSequence() throws {
        let yaml = """
        -
          - a
          - b
        -
          - c
          - d
        """
        let node = try YAML.load(yaml)
        XCTAssertEqual(node.size, 2)
    }

    func testMultilineScalar() throws {
        let yaml = """
        key: |
          line1
          line2
        """
        let node = try YAML.load(yaml)
        let val = node["key"].scalar
        XCTAssertTrue(val.contains("line1"))
        XCTAssertTrue(val.contains("line2"))
    }

    func testSpecialCharacters() throws {
        let node = try YAML.load("\"hello\\nworld\"")
        XCTAssertTrue(node.scalar.contains("\n"))
    }
}
