//
//  StringOutput.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

final class StringOutput {
    private var buffer: [UInt8] = []
    private(set) var row: Int = 0
    private(set) var col: Int = 0
    private(set) var pos: Int = 0
    private(set) var isComment: Bool = false

    init() {}

    func write(_ str: String) {
        for byte in str.utf8 {
            buffer.append(byte)
            updatePos(byte)
        }
    }

    func write(_ ch: UInt8) {
        buffer.append(ch)
        updatePos(ch)
    }

    func writeChar(_ ch: Character) {
        for byte in String(ch).utf8 {
            buffer.append(byte)
            updatePos(byte)
        }
    }

    func setComment() { isComment = true }

    var string: String {
        String(bytes: buffer, encoding: .utf8) ?? ""
    }

    private func updatePos(_ ch: UInt8) {
        pos += 1
        col += 1
        if ch == UInt8(ascii: "\n") {
            row += 1
            col = 0
            isComment = false
        }
    }

    // Indentation helpers
    func writeIndentation(_ n: Int) {
        for _ in 0..<n {
            write(UInt8(ascii: " "))
        }
    }

    func writeIndentTo(_ column: Int) {
        while col < column {
            write(UInt8(ascii: " "))
        }
    }
}
