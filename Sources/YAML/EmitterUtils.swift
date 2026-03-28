//
//  EmitterUtils.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

enum StringFormat { case plain, singleQuoted, doubleQuoted, literal }
enum StringEscaping { case none, nonAscii, json }

enum EmitterUtils {
    static func computeStringFormat(_ str: String, format: EmitterManip, flowType: FlowType, escapeNonAscii: Bool) -> StringFormat {
        switch format {
        case .auto_:
            if isValidPlainScalar(str, flowType: flowType, allowOnlyAscii: escapeNonAscii) { return .plain }
            return .doubleQuoted
        case .singleQuoted:
            if !str.contains("\n") { return .singleQuoted }
            return .doubleQuoted
        case .doubleQuoted:
            return .doubleQuoted
        case .literal:
            if flowType != .flow { return .literal }
            return .doubleQuoted
        default:
            return .doubleQuoted
        }
    }

    static func isValidPlainScalar(_ str: String, flowType: FlowType, allowOnlyAscii: Bool) -> Bool {
        if isNullString(str) { return false }
        if str.isEmpty { return false }

        // Check first character
        let first = str.first!
        if " \t\n\r".contains(first) { return false }
        if "-?:,[]{}#&*!|>'\"%@`".contains(first) { return false }

        // Check trailing space
        if str.last == " " { return false }

        // Check for disallowed patterns
        for (i, ch) in str.enumerated() {
            if ch == ":" && i + 1 < str.count {
                let next = str[str.index(str.startIndex, offsetBy: i + 1)]
                if next == " " || next == "\n" || next == "\r" { return false }
            }
            if ch == "#" && i > 0 {
                let prev = str[str.index(str.startIndex, offsetBy: i - 1)]
                if prev == " " || prev == "\t" { return false }
            }
            if ch == "\n" || ch == "\r" || ch == "\t" { return false }
            if ch == "&" { return false }
            if flowType == .flow && (ch == "," || ch == "[" || ch == "]" || ch == "{" || ch == "}") { return false }
            if allowOnlyAscii && ch.asciiValue == nil { return false }
        }

        return true
    }

    static func writeSingleQuotedString(_ out: StringOutput, _ str: String) {
        out.write("'")
        for ch in str {
            if ch == "'" { out.write("''") }
            else { out.writeChar(ch) }
        }
        out.write("'")
    }

    static func writeDoubleQuotedString(_ out: StringOutput, _ str: String, escaping: StringEscaping = .none) {
        out.write("\"")
        for ch in str {
            switch ch {
            case "\"": out.write("\\\"")
            case "\\": out.write("\\\\")
            case "\n": out.write("\\n")
            case "\t": out.write("\\t")
            case "\r": out.write("\\r")
            case "\u{08}": out.write("\\b")
            case "\u{0C}": out.write("\\f")
            default:
                let v = ch.unicodeScalars.first!.value
                if v < 0x20 || (v >= 0x80 && v <= 0xA0) || v == 0xFEFF {
                    writeEscapeSequence(out, Int(v), escaping)
                } else if escaping == .nonAscii && v > 0x7E {
                    writeEscapeSequence(out, Int(v), escaping)
                } else {
                    out.writeChar(ch)
                }
            }
        }
        out.write("\"")
    }

    static func writeLiteralString(_ out: StringOutput, _ str: String, indent: Int) {
        out.write("|\n")
        for ch in str {
            if ch == "\n" {
                out.write("\n")
            } else {
                out.writeIndentTo(indent)
                out.writeChar(ch)
            }
        }
    }

    static func writeComment(_ out: StringOutput, _ str: String, postCommentIndent: Int) {
        let curIndent = out.col
        out.write("#")
        out.writeIndentation(postCommentIndent)
        out.setComment()
        for ch in str {
            if ch == "\n" {
                out.write("\n")
                out.writeIndentTo(curIndent)
                out.write("#")
                out.writeIndentation(postCommentIndent)
                out.setComment()
            } else {
                out.writeChar(ch)
            }
        }
    }

    @discardableResult
    static func writeAlias(_ out: StringOutput, _ str: String) -> Bool {
        out.write("*")
        out.write(str)
        return true
    }

    @discardableResult
    static func writeAnchor(_ out: StringOutput, _ str: String) -> Bool {
        out.write("&")
        out.write(str)
        return true
    }

    @discardableResult
    static func writeTag(_ out: StringOutput, _ str: String, verbatim: Bool) -> Bool {
        out.write(verbatim ? "!<" : "!")
        out.write(str)
        if verbatim { out.write(">") }
        return true
    }

    @discardableResult
    static func writeTagWithPrefix(_ out: StringOutput, prefix: String, tag: String) -> Bool {
        out.write("!")
        out.write(prefix)
        out.write("!")
        out.write(tag)
        return true
    }

    static func writeBinary(_ out: StringOutput, _ binary: Binary) {
        let encoded = encodeBase64(binary.data)
        writeDoubleQuotedString(out, encoded)
    }

    static func writeChar(_ out: StringOutput, _ ch: Character, escaping: StringEscaping = .none) {
        if ch.isLetter {
            out.writeChar(ch)
        } else if ch == "\"" {
            out.write("\"\\\"\"")
        } else if ch == "\t" {
            out.write("\"\\t\"")
        } else if ch == "\n" {
            out.write("\"\\n\"")
        } else if ch == "\r" {
            out.write("\"\\r\"")
        } else if ch == "\\" {
            out.write("\"\\\\\"")
        } else {
            let v = ch.unicodeScalars.first!.value
            if v >= 0x20 && v <= 0x7E {
                out.write("\"")
                out.writeChar(ch)
                out.write("\"")
            } else {
                out.write("\"")
                writeEscapeSequence(out, Int(v), escaping)
                out.write("\"")
            }
        }
    }

    private static func writeEscapeSequence(_ out: StringOutput, _ codePoint: Int, _ style: StringEscaping) {
        let hexDigits = "0123456789abcdef"
        out.write("\\")
        var digits: Int
        if codePoint < 0xFF && style != .json {
            out.write("x"); digits = 2
        } else if codePoint < 0xFFFF {
            out.write("u"); digits = 4
        } else if style != .json {
            out.write("U"); digits = 8
        } else {
            // JSON surrogate pair
            let high = 0xD800 + ((codePoint - 0x10000) >> 10)
            let low = 0xDC00 + ((codePoint - 0x10000) & 0x3FF)
            writeEscapeSequence(out, high, style)
            writeEscapeSequence(out, low, style)
            return
        }
        for i in stride(from: digits - 1, through: 0, by: -1) {
            let idx = (codePoint >> (4 * i)) & 0xF
            out.write(String(hexDigits[hexDigits.index(hexDigits.startIndex, offsetBy: idx)]))
        }
    }
}
