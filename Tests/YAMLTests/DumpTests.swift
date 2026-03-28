//
//  DumpTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class DumpTests: XCTestCase {
    func testDumpScalar() throws {
        let node = try YAML.load("Hello")
        let result = YAML.dump(node)
        XCTAssertTrue(result.contains("Hello"))
    }

    func testDumpSequence() throws {
        let node = try YAML.load("[1, 2, 3]")
        let result = YAML.dump(node)
        XCTAssertFalse(result.isEmpty)
    }

    func testDumpMap() throws {
        let node = try YAML.load("key: value")
        let result = YAML.dump(node)
        XCTAssertTrue(result.contains("key"))
        XCTAssertTrue(result.contains("value"))
    }

    func testRoundTrip() throws {
        let yaml = """
        name: John
        age: 30
        """
        let node = try YAML.load(yaml)
        let dumped = YAML.dump(node)
        let reloaded = try YAML.load(dumped)
        XCTAssertEqual(reloaded["name"].scalar, "John")
        XCTAssertEqual(reloaded["age"].scalar, "30")
    }

    func testRoundTripSequence() throws {
        let yaml = "[1, 2, 3]"
        let node = try YAML.load(yaml)
        let dumped = YAML.dump(node)
        let reloaded = try YAML.load(dumped)
        XCTAssertEqual(reloaded.size, 3)
    }
}
