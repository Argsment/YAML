//
//  PatternMatcherTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class PatternMatcherTests: XCTestCase {
    func testSingleCharMatch() {
        let re = PatternMatcher(char: "a")
        XCTAssertTrue(re.matches(StringReader("abc")))
        XCTAssertFalse(re.matches(StringReader("xyz")))
    }

    func testRangeMatch() {
        let re = PatternMatcher(range: "a", "z")
        XCTAssertTrue(re.matches(StringReader("m")))
        XCTAssertFalse(re.matches(StringReader("A")))
    }

    func testOrMatch() {
        let re = PatternMatcher(char: "a") | PatternMatcher(char: "b")
        XCTAssertTrue(re.matches(StringReader("a")))
        XCTAssertTrue(re.matches(StringReader("b")))
        XCTAssertFalse(re.matches(StringReader("c")))
    }

    func testSequenceMatch() {
        let re = PatternMatcher(char: "a") + PatternMatcher(char: "b")
        XCTAssertTrue(re.matches(StringReader("ab")))
        XCTAssertFalse(re.matches(StringReader("ac")))
    }

    func testNotMatch() {
        let re = !PatternMatcher(char: "a")
        XCTAssertFalse(re.matches(StringReader("a")))
        XCTAssertTrue(re.matches(StringReader("b")))
    }

    func testBlankMatch() {
        let blank = Pattern.blank()
        XCTAssertTrue(blank.matches(StringReader(" ")))
        XCTAssertTrue(blank.matches(StringReader("\t")))
        XCTAssertFalse(blank.matches(StringReader("a")))
    }

    func testBreakMatch() {
        let brk = Pattern.breakChar()
        XCTAssertTrue(brk.matches(StringReader("\n")))
        XCTAssertTrue(brk.matches(StringReader("\r")))
        XCTAssertFalse(brk.matches(StringReader(" ")))
    }
}
