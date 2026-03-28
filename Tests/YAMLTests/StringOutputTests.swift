//
//  StringOutputTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class StringOutputTests: XCTestCase {
    func testEmptyOutput() {
        let out = StringOutput()
        XCTAssertEqual(out.string, "")
        XCTAssertEqual(out.col, 0)
        XCTAssertEqual(out.row, 0)
    }

    func testWriteString() {
        let out = StringOutput()
        out.write("hello")
        XCTAssertEqual(out.string, "hello")
        XCTAssertEqual(out.col, 5)
    }

    func testWriteNewline() {
        let out = StringOutput()
        out.write("hello\nworld")
        XCTAssertEqual(out.row, 1)
        XCTAssertEqual(out.col, 5)
    }

    func testWriteIndentation() {
        let out = StringOutput()
        out.writeIndentation(4)
        XCTAssertEqual(out.col, 4)
        XCTAssertEqual(out.string, "    ")
    }
}
