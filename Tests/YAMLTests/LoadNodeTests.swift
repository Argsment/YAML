//
//  LoadNodeTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class LoadNodeTests: XCTestCase {
    func testLoadEmptyString() throws {
        let node = try YAML.load("")
        XCTAssertTrue(!node.isDefined || node.isNull)
    }

    func testLoadScalar() throws {
        let node = try YAML.load("Hello")
        XCTAssertTrue(node.isScalar)
        XCTAssertEqual(node.scalar, "Hello")
    }

    func testLoadFlowSequence() throws {
        let node = try YAML.load("[1, 2, 3]")
        XCTAssertTrue(node.isSequence)
        XCTAssertEqual(node.size, 3)
    }

    func testLoadFlowMap() throws {
        let node = try YAML.load("{key: value}")
        XCTAssertTrue(node.isMap)
    }

    func testLoadBlockSequence() throws {
        let yaml = """
        - one
        - two
        - three
        """
        let node = try YAML.load(yaml)
        XCTAssertTrue(node.isSequence)
        XCTAssertEqual(node.size, 3)
    }

    func testLoadBlockMap() throws {
        let yaml = """
        key1: value1
        key2: value2
        """
        let node = try YAML.load(yaml)
        XCTAssertTrue(node.isMap)
        XCTAssertEqual(node["key1"].scalar, "value1")
        XCTAssertEqual(node["key2"].scalar, "value2")
    }

    func testLoadNestedMap() throws {
        let yaml = """
        outer:
          inner: value
        """
        let node = try YAML.load(yaml)
        XCTAssertEqual(node["outer"]["inner"].scalar, "value")
    }

    func testLoadMultipleDocuments() throws {
        let yaml = """
        ---
        first
        ---
        second
        ---
        third
        """
        let docs = try YAML.loadAll(yaml)
        XCTAssertEqual(docs.count, 3)
    }

    func testLoadQuotedStrings() throws {
        let node = try YAML.load("\"quoted string\"")
        XCTAssertEqual(node.scalar, "quoted string")
    }

    func testLoadEscapeSequences() throws {
        let node = try YAML.load("\"line1\\nline2\"")
        XCTAssertEqual(node.scalar, "line1\nline2")
    }
}
