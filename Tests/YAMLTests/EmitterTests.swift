//
//  EmitterTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class EmitterTests: XCTestCase {
    func testSimpleScalar() {
        let emitter = Emitter()
        emitter.emit("Hello")
        XCTAssertEqual(emitter.string, "Hello")
    }

    func testSimpleSequence() {
        let emitter = Emitter()
        emitter.emit(.beginSeq)
        emitter.emit("one")
        emitter.emit("two")
        emitter.emit("three")
        emitter.emit(.endSeq)
        XCTAssertTrue(emitter.string.contains("- one"))
        XCTAssertTrue(emitter.string.contains("- two"))
        XCTAssertTrue(emitter.string.contains("- three"))
    }

    func testSimpleMap() {
        let emitter = Emitter()
        emitter.emit(.beginMap)
        emitter.emit("name")
        emitter.emit("John")
        emitter.emit("age")
        emitter.emit("30")
        emitter.emit(.endMap)
        XCTAssertTrue(emitter.string.contains("name"))
        XCTAssertTrue(emitter.string.contains("John"))
    }

    func testFlowSequence() {
        let emitter = Emitter()
        emitter.emit(.flow)
        emitter.emit(.beginSeq)
        emitter.emit("1")
        emitter.emit("2")
        emitter.emit("3")
        emitter.emit(.endSeq)
        XCTAssertTrue(emitter.string.contains("["))
        XCTAssertTrue(emitter.string.contains("]"))
    }

    func testFlowMap() {
        let emitter = Emitter()
        emitter.emit(.flow)
        emitter.emit(.beginMap)
        emitter.emit("a")
        emitter.emit("1")
        emitter.emit(.endMap)
        XCTAssertTrue(emitter.string.contains("{"))
        XCTAssertTrue(emitter.string.contains("}"))
    }

    func testEmptySequence() {
        let emitter = Emitter()
        emitter.emit(.beginSeq)
        emitter.emit(.endSeq)
        XCTAssertTrue(emitter.string.contains("[]"))
    }

    func testEmptyMap() {
        let emitter = Emitter()
        emitter.emit(.beginMap)
        emitter.emit(.endMap)
        XCTAssertTrue(emitter.string.contains("{}"))
    }

    func testNullValue() {
        let emitter = Emitter()
        emitter.emitNull()
        XCTAssertEqual(emitter.string, "~")
    }

    func testBoolValue() {
        let emitter = Emitter()
        emitter.emit(true)
        XCTAssertEqual(emitter.string, "true")
    }

    func testIntValue() {
        let emitter = Emitter()
        emitter.emit(42)
        XCTAssertEqual(emitter.string, "42")
    }

    func testDoubleValue() {
        let emitter = Emitter()
        emitter.emit(3.14)
        XCTAssertTrue(emitter.good)
    }

    func testComment() {
        let emitter = Emitter()
        emitter.emit(YAML.Comment("This is a comment"))
        emitter.emit("value")
        XCTAssertTrue(emitter.string.contains("#"))
    }

    func testDocument() {
        let emitter = Emitter()
        emitter.emit(.beginDoc)
        emitter.emit("hello")
        emitter.emit(.endDoc)
        XCTAssertTrue(emitter.string.contains("---"))
        XCTAssertTrue(emitter.string.contains("..."))
    }

    func testNestedStructure() {
        let emitter = Emitter()
        emitter.emit(.beginMap)
        emitter.emit("people")
        emitter.emit(.beginSeq)
        emitter.emit(.beginMap)
        emitter.emit("name")
        emitter.emit("John")
        emitter.emit(.endMap)
        emitter.emit(.endSeq)
        emitter.emit(.endMap)
        XCTAssertTrue(emitter.good)
    }
}
