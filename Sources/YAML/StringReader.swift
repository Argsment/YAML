//
//  StringReader.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

struct StringReader {
    private let chars: [Character]
    private let offset: Int

    init(_ str: String) {
        self.chars = Array(str)
        self.offset = 0
    }

    init(chars: [Character], offset: Int) {
        self.chars = chars
        self.offset = offset
    }

    var hasMore: Bool {
        offset < chars.count
    }

    subscript(index: Int) -> Character {
        chars[offset + index]
    }

    func advance(by n: Int) -> StringReader {
        StringReader(chars: chars, offset: offset + n)
    }

    mutating func increment() {
        // This is used in loops - we'll use a separate mutable version
    }
}

// Mutable iterator version
struct MutableStringReader {
    private let chars: [Character]
    private(set) var offset: Int

    init(_ str: String) {
        self.chars = Array(str)
        self.offset = 0
    }

    init(chars: [Character], offset: Int = 0) {
        self.chars = chars
        self.offset = offset
    }

    var hasMore: Bool { offset < chars.count }

    subscript(index: Int) -> Character {
        chars[offset + index]
    }

    func asSource() -> StringReader {
        StringReader(chars: chars, offset: offset)
    }

    mutating func advance() {
        offset += 1
    }
}
