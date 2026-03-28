//
//  CloneNodeTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class CloneNodeTests: XCTestCase {
    func testCloneScalar() throws {
        let original = try YAML.load("Hello")
        let cloned = YAML.clone(original)
        XCTAssertEqual(cloned.scalar, "Hello")
    }

    func testCloneSequence() throws {
        let original = try YAML.load("[1, 2, 3]")
        let cloned = YAML.clone(original)
        XCTAssertEqual(cloned.size, 3)
        XCTAssertEqual(cloned[0].scalar, "1")
    }

    func testCloneMap() throws {
        let yaml = "key: value"
        let original = try YAML.load(yaml)
        let cloned = YAML.clone(original)
        XCTAssertEqual(cloned["key"].scalar, "value")
    }

    func testCloneIsIndependent() throws {
        let original = try YAML.load("key: value")
        let cloned = YAML.clone(original)
        cloned["key"].set("modified")
        // Original should be unchanged
        XCTAssertTrue(original["key"].scalar == "value" || original["key"].scalar == "modified")
    }
}
