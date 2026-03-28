//
//  Stream.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import Foundation

private let prefetchSize = 2048

final class Stream {
    private var chars: [UInt8]
    private var readPos: Int = 0
    private(set) var markPos: Mark = Mark()
    private var lineEndingSymbol: UInt8 = 0

    static let eof: UInt8 = 0x04

    init(_ input: String) {
        var bytes = Array(input.utf8)
        // Skip BOM if present
        if bytes.count >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF {
            bytes.removeFirst(3)
        } else if bytes.count >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF {
            // UTF-16 BE BOM - convert (shouldn't happen with Swift strings)
            bytes.removeFirst(2)
        } else if bytes.count >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE {
            // UTF-16 LE BOM
            bytes.removeFirst(2)
        }
        self.chars = bytes
    }

    var isValid: Bool {
        readPos < chars.count
    }

    func peek() -> UInt8 {
        guard readPos < chars.count else { return Stream.eof }
        return chars[readPos]
    }

    @discardableResult
    func get() -> UInt8 {
        guard readPos < chars.count else { return Stream.eof }
        let ch = chars[readPos]
        readPos += 1
        markPos.pos += 1
        markPos.column += 1

        // Determine line ending
        if lineEndingSymbol == 0 {
            if ch == 0x0A { // \n
                lineEndingSymbol = 0x0A
            } else if ch == 0x0D { // \r
                if readPos < chars.count && chars[readPos] == 0x0A {
                    lineEndingSymbol = 0x0A
                } else {
                    lineEndingSymbol = 0x0D
                }
            }
        }

        if ch == lineEndingSymbol {
            markPos.column = 0
            markPos.line += 1
        }

        return ch
    }

    func getChar() -> Character {
        let byte = get()
        // Handle multi-byte UTF-8
        if byte < 0x80 {
            return Character(UnicodeScalar(byte))
        }
        // For multi-byte, we need to read continuation bytes
        var codePoint: UInt32 = 0
        var remaining = 0
        if byte & 0xE0 == 0xC0 {
            codePoint = UInt32(byte & 0x1F)
            remaining = 1
        } else if byte & 0xF0 == 0xE0 {
            codePoint = UInt32(byte & 0x0F)
            remaining = 2
        } else if byte & 0xF8 == 0xF0 {
            codePoint = UInt32(byte & 0x07)
            remaining = 3
        } else {
            return "\u{FFFD}"
        }
        for _ in 0..<remaining {
            guard readPos < chars.count else { return "\u{FFFD}" }
            let cont = chars[readPos]
            guard cont & 0xC0 == 0x80 else { return "\u{FFFD}" }
            codePoint = (codePoint << 6) | UInt32(cont & 0x3F)
            readPos += 1
            markPos.pos += 1
        }
        guard let scalar = UnicodeScalar(codePoint) else { return "\u{FFFD}" }
        return Character(scalar)
    }

    func get(n: Int) -> String {
        var result = ""
        result.reserveCapacity(n)
        for _ in 0..<n {
            let ch = get()
            result.append(Character(UnicodeScalar(ch)))
        }
        return result
    }

    func eat(_ n: Int = 1) {
        for _ in 0..<n {
            get()
        }
    }

    var mark: Mark { markPos }
    var pos: Int { markPos.pos }
    var line: Int { markPos.line }
    var column: Int { markPos.column }

    func resetColumn() { markPos.column = 0 }

    // For StreamReader compatibility
    func charAt(_ index: Int) -> UInt8 {
        let pos = readPos + index
        guard pos < chars.count else { return Stream.eof }
        return chars[pos]
    }

    func readAheadTo(_ i: Int) -> Bool {
        readPos + i < chars.count
    }
}

extension Stream {
    // Allow the stream to be used as a boolean
    var asBool: Bool { isValid }
}
