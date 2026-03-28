//
//  Patterns.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

// Character constants used in YAML
enum YAMLCharacter {
    static let flowSeqStart: UInt8 = UInt8(ascii: "[")
    static let flowSeqEnd: UInt8 = UInt8(ascii: "]")
    static let flowMapStart: UInt8 = UInt8(ascii: "{")
    static let flowMapEnd: UInt8 = UInt8(ascii: "}")
    static let flowEntry: UInt8 = UInt8(ascii: ",")
    static let alias: UInt8 = UInt8(ascii: "*")
    static let anchor: UInt8 = UInt8(ascii: "&")
    static let tag: UInt8 = UInt8(ascii: "!")
    static let key: UInt8 = UInt8(ascii: "?")
    static let value: UInt8 = UInt8(ascii: ":")
    static let comment: UInt8 = UInt8(ascii: "#")
    static let directive: UInt8 = UInt8(ascii: "%")
    static let literalScalar: UInt8 = UInt8(ascii: "|")
    static let foldedScalar: UInt8 = UInt8(ascii: ">")
    static let verbatimTagStart: UInt8 = UInt8(ascii: "<")
    static let verbatimTagEnd: UInt8 = UInt8(ascii: ">")
}

// Pattern definitions used by the scanner
enum Pattern {
    // Single character patterns
    static func blank() -> PatternMatcher { PatternMatcher(char: " ") | PatternMatcher(char: "\t") }
    static func breakChar() -> PatternMatcher { PatternMatcher(char: "\n") | PatternMatcher(char: "\r") }
    static func blankOrBreak() -> PatternMatcher { blank() | breakChar() }
    static func digit() -> PatternMatcher { PatternMatcher(range: "0", "9") }
    static func alpha() -> PatternMatcher { PatternMatcher(range: "a", "z") | PatternMatcher(range: "A", "Z") }
    static func hexDigit() -> PatternMatcher { digit() | PatternMatcher(range: "a", "f") | PatternMatcher(range: "A", "F") }
    static func wordChar() -> PatternMatcher { alpha() | digit() | PatternMatcher(char: "-") }
    static func comment() -> PatternMatcher { PatternMatcher(char: "#") }
    static func tab() -> PatternMatcher { PatternMatcher(char: "\t") }
    static func empty() -> PatternMatcher { PatternMatcher(.empty) }

    // BOM
    static func utf8ByteOrderMark() -> PatternMatcher {
        PatternMatcher(char: Character(UnicodeScalar(UInt32(0xFEFF))!))
    }

    // Ampersand (for emitter utils)
    static func ampersand() -> PatternMatcher { PatternMatcher(char: "&") }

    // Not printable
    static func notPrintable() -> PatternMatcher {
        // A character is "not printable" if it's a control char (< 0x20) that isn't tab/LF/CR,
        // or DEL (0x7F), etc. We define printable and negate it.
        let printable = PatternMatcher(range: " ", "~") | PatternMatcher(char: "\t") | PatternMatcher(char: "\n") | PatternMatcher(char: "\r")
        return !printable
    }

    // Anchor/Alias character patterns
    static func anchor() -> PatternMatcher {
        wordChar() | PatternMatcher(char: ".") | PatternMatcher(char: ":") | PatternMatcher(char: "/")
    }

    static func anchorEnd() -> PatternMatcher {
        blankOrBreak() |
        PatternMatcher(char: "?") | PatternMatcher(char: ",") |
        PatternMatcher(char: "]") | PatternMatcher(char: "}") |
        PatternMatcher(char: "%") | PatternMatcher(char: "@") | PatternMatcher(char: "`")
    }

    // Document indicator
    static func docIndicator() -> PatternMatcher {
        (PatternMatcher(string: "---") | PatternMatcher(string: "...")) + (blankOrBreak() | PatternMatcher(.empty))
    }

    // Chomp indicator
    static func chomp() -> PatternMatcher {
        PatternMatcher(char: "+") | PatternMatcher(char: "-") | digit()
    }

    // Escape patterns
    static func escBreak() -> PatternMatcher {
        PatternMatcher(char: "\\") + breakChar()
    }

    static func escSingleQuote() -> PatternMatcher {
        PatternMatcher(char: "'") + PatternMatcher(char: "'")
    }

    // Scalar end patterns
    static func endScalar() -> PatternMatcher {
        PatternMatcher(char: ":") + blankOrBreak()
    }

    static func endScalarInFlow() -> PatternMatcher {
        (PatternMatcher(char: ":") + blankOrBreak()) | PatternMatcher(char: ",") | PatternMatcher(char: "]") | PatternMatcher(char: "}")
    }

    // Scan scalar end patterns
    static func scanScalarEnd() -> PatternMatcher {
        endScalar()
    }

    static func scanScalarEndInFlow() -> PatternMatcher {
        endScalarInFlow()
    }

    // Plain scalar patterns
    static func plainScalar() -> PatternMatcher {
        // Cannot start with indicators or blank/break
        !blankOrBreak() & !comment() &
        !PatternMatcher(char: "-") & !PatternMatcher(char: "?") & !PatternMatcher(char: ":") &
        !PatternMatcher(char: ",") & !PatternMatcher(char: "[") & !PatternMatcher(char: "]") &
        !PatternMatcher(char: "{") & !PatternMatcher(char: "}") & !PatternMatcher(char: "#") &
        !PatternMatcher(char: "&") & !PatternMatcher(char: "*") & !PatternMatcher(char: "!") &
        !PatternMatcher(char: "|") & !PatternMatcher(char: ">") & !PatternMatcher(char: "'") &
        !PatternMatcher(char: "\"") & !PatternMatcher(char: "%") & !PatternMatcher(char: "@") &
        !PatternMatcher(char: "`")
    }

    static func plainScalarInFlow() -> PatternMatcher {
        plainScalar()
    }

    // Tag patterns
    static func tag() -> PatternMatcher {
        wordChar() | PatternMatcher(char: "%") | PatternMatcher(char: "#") | PatternMatcher(char: "/") |
        PatternMatcher(char: ";") | PatternMatcher(char: "?") | PatternMatcher(char: ":") | PatternMatcher(char: "@") |
        PatternMatcher(char: "&") | PatternMatcher(char: "=") | PatternMatcher(char: "+") | PatternMatcher(char: "$") |
        PatternMatcher(char: ".") | PatternMatcher(char: "~") | PatternMatcher(char: "*") | PatternMatcher(char: "'") |
        PatternMatcher(char: "(") | PatternMatcher(char: ")")
    }

    static func uri() -> PatternMatcher {
        tag() | PatternMatcher(char: "!") | PatternMatcher(char: ",") | PatternMatcher(char: "[") | PatternMatcher(char: "]")
    }

    // Parse hex to unicode code point
    static func parseHex(_ str: String, mark: Mark) throws -> UInt32 {
        var value: UInt32 = 0
        for ch in str {
            let d: UInt32
            switch ch {
            case "a"..."f":
                d = UInt32(ch.asciiValue!) - UInt32(Character("a").asciiValue!) + 10
            case "A"..."F":
                d = UInt32(ch.asciiValue!) - UInt32(Character("A").asciiValue!) + 10
            case "0"..."9":
                d = UInt32(ch.asciiValue!) - UInt32(Character("0").asciiValue!)
            default:
                throw YAMLError.parser(mark: mark, message: ErrorMsg.INVALID_HEX)
            }
            value = (value << 4) + d
        }
        return value
    }

    // Escape a hex code point of given length
    static func escapeHex(_ stream: Stream, codeLength: Int) throws -> String {
        var str = ""
        for _ in 0..<codeLength {
            str.append(Character(UnicodeScalar(stream.get())))
        }
        let value = try parseHex(str, mark: stream.mark)

        // Legal unicode check
        if (value >= 0xD800 && value <= 0xDFFF) || value > 0x10FFFF {
            throw YAMLError.parser(mark: stream.mark, message: "\(ErrorMsg.INVALID_UNICODE)\(value)")
        }

        guard let scalar = UnicodeScalar(value) else {
            throw YAMLError.parser(mark: stream.mark, message: "\(ErrorMsg.INVALID_UNICODE)\(value)")
        }
        return String(scalar)
    }

    // Escape a sequence starting from the stream
    static func escape(_ stream: Stream) throws -> String {
        let escape = stream.get()  // eat the escape char
        let ch = stream.get()

        // Single quote escape
        if escape == UInt8(ascii: "'") && ch == UInt8(ascii: "'") {
            return "'"
        }

        // Backslash escapes
        switch ch {
        case UInt8(ascii: "0"): return "\0"
        case UInt8(ascii: "a"): return "\u{07}"
        case UInt8(ascii: "b"): return "\u{08}"
        case UInt8(ascii: "t"), 0x09: return "\t"
        case UInt8(ascii: "n"): return "\n"
        case UInt8(ascii: "v"): return "\u{0B}"
        case UInt8(ascii: "f"): return "\u{0C}"
        case UInt8(ascii: "r"): return "\r"
        case UInt8(ascii: "e"): return "\u{1B}"
        case UInt8(ascii: " "): return " "
        case UInt8(ascii: "\""): return "\""
        case UInt8(ascii: "'"): return "'"
        case UInt8(ascii: "\\"): return "\\"
        case UInt8(ascii: "/"): return "/"
        case UInt8(ascii: "N"): return "\u{0085}"    // NEL
        case UInt8(ascii: "_"): return "\u{00A0}"    // NBSP
        case UInt8(ascii: "L"): return "\u{2028}"    // LS
        case UInt8(ascii: "P"): return "\u{2029}"    // PS
        case UInt8(ascii: "x"): return try escapeHex(stream, codeLength: 2)
        case UInt8(ascii: "u"): return try escapeHex(stream, codeLength: 4)
        case UInt8(ascii: "U"): return try escapeHex(stream, codeLength: 8)
        default:
            let char = Character(UnicodeScalar(ch))
            throw YAMLError.parser(mark: stream.mark, message: "\(ErrorMsg.INVALID_ESCAPE)\(char)")
        }
    }
}
