//
//  NodeTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class NodeTests: XCTestCase {
    func testSimpleScalar() throws {
        let node = try YAML.load("Hello, World!")
        XCTAssertTrue(node.isScalar)
        XCTAssertEqual(node.scalar, "Hello, World!")
    }

    func testIntScalar() throws {
        let node = try YAML.load("15")
        XCTAssertEqual(node.as(Int.self), 15)
    }

    func testFloatScalar() throws {
        let node = try YAML.load("1.5")
        XCTAssertEqual(node.as(Double.self), 1.5)
    }

    func testBoolScalar() throws {
        let trueNode = try YAML.load("true")
        XCTAssertEqual(trueNode.as(Bool.self), true)

        let falseNode = try YAML.load("false")
        XCTAssertEqual(falseNode.as(Bool.self), false)
    }

    func testNullScalar() throws {
        let node = try YAML.load("~")
        XCTAssertTrue(node.isNull)
    }

    func testSimpleSequence() throws {
        let node = try YAML.load("[1, 2, 3]")
        XCTAssertTrue(node.isSequence)
        XCTAssertEqual(node.size, 3)
        XCTAssertEqual(node[0].scalar, "1")
        XCTAssertEqual(node[1].scalar, "2")
        XCTAssertEqual(node[2].scalar, "3")
    }

    func testSimpleMap() throws {
        let node = try YAML.load("name: John")
        XCTAssertTrue(node.isMap)
        XCTAssertEqual(node["name"].scalar, "John")
    }

    func testNestedMap() throws {
        let yaml = """
        person:
          name: John
          age: 30
        """
        let node = try YAML.load(yaml)
        XCTAssertEqual(node["person"]["name"].scalar, "John")
        XCTAssertEqual(node["person"]["age"].scalar, "30")
    }

    func testSequenceOfMaps() throws {
        let yaml = """
        - name: John
          age: 30
        - name: Jane
          age: 25
        """
        let node = try YAML.load(yaml)
        XCTAssertTrue(node.isSequence)
        XCTAssertEqual(node.size, 2)
        XCTAssertEqual(node[0]["name"].scalar, "John")
        XCTAssertEqual(node[1]["name"].scalar, "Jane")
    }

    func testBlockSequence() throws {
        let yaml = """
        - one
        - two
        - three
        """
        let node = try YAML.load(yaml)
        XCTAssertTrue(node.isSequence)
        XCTAssertEqual(node.size, 3)
    }

    func testEmptyDoc() throws {
        let node = try YAML.load("")
        XCTAssertTrue(!node.isDefined || node.isNull)
    }

    func testMultipleDocuments() throws {
        let yaml = """
        ---
        doc1
        ---
        doc2
        """
        let docs = try YAML.loadAll(yaml)
        XCTAssertEqual(docs.count, 2)
        XCTAssertEqual(docs[0].scalar, "doc1")
        XCTAssertEqual(docs[1].scalar, "doc2")
    }

    func testQuotedString() throws {
        let node = try YAML.load("\"hello world\"")
        XCTAssertEqual(node.scalar, "hello world")
    }

    func testSingleQuotedString() throws {
        let node = try YAML.load("'hello world'")
        XCTAssertEqual(node.scalar, "hello world")
    }

    func testFlowMapping() throws {
        let node = try YAML.load("{a: 1, b: 2}")
        XCTAssertTrue(node.isMap)
        XCTAssertEqual(node["a"].scalar, "1")
        XCTAssertEqual(node["b"].scalar, "2")
    }

    func testNullValues() throws {
        let yaml = """
        a: ~
        b: null
        c: Null
        d: NULL
        """
        let node = try YAML.load(yaml)
        XCTAssertTrue(node["a"].isNull)
        XCTAssertTrue(node["b"].isNull)
        XCTAssertTrue(node["c"].isNull)
        XCTAssertTrue(node["d"].isNull)
    }

    func testAnchor() throws {
        let yaml = """
        defaults: &defaults
          adapter: postgres
          host: localhost
        development:
          <<: *defaults
          database: dev_db
        """
        // Just test it parses without error
        let node = try YAML.load(yaml)
        XCTAssertTrue(node.isMap)
    }
}
