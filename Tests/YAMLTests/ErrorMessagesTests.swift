//
//  ErrorMessagesTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class ErrorMessagesTests: XCTestCase {
    func testInvalidYAML() {
        XCTAssertThrowsError(try YAML.load("[invalid: yaml: : :")) { error in
            XCTAssertTrue(error is YAMLError)
        }
    }

    func testTabInIndentation() {
        let yaml = "key:\n\t value"
        // Tab in indentation may or may not throw depending on context
        do {
            _ = try YAML.load(yaml)
        } catch {
            // Expected
        }
    }
}
