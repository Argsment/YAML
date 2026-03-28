//
//  BinaryTests.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import XCTest
@testable import YAML

final class BinaryTests: XCTestCase {
    func testDecodingSimple() {
        let input = "ZGVhZGJlZWY="
        let result = decodeBase64(input)
        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(String(bytes: result, encoding: .utf8), "deadbeef")
        }
    }

    func testDecodingTooShort() {
        let input = "ZGVhZGJlZWY"  // Missing padding
        let result = decodeBase64(input)
        XCTAssertNil(result)
    }

    func testEncodingRoundTrip() {
        let original: [UInt8] = Array("Hello, World!".utf8)
        let encoded = encodeBase64(original)
        let decoded = decodeBase64(encoded)
        XCTAssertEqual(decoded, original)
    }
}
