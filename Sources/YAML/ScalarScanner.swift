//
//  ScanScalar.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

enum Chomp { case strip, clip, keep }
enum ScalarAction { case none, `break`, `throw` }
enum Fold { case dontFold, foldBlock, foldFlow }

struct ScanScalarParams {
    var end: PatternMatcher?
    var eatEnd: Bool = false
    var indent: Int = 0
    var detectIndent: Bool = false
    var eatLeadingWhitespace: Bool = false
    var escape: UInt8 = 0
    var fold: Fold = .dontFold
    var trimTrailingSpaces: Bool = false
    var chomp: Chomp = .clip
    var onDocIndicator: ScalarAction = .none
    var onTabInIndentation: ScalarAction = .none
    var leadingSpaces: Bool = false
}

func scanScalar(_ input: Stream, _ params: inout ScanScalarParams) throws -> String {
    var foundNonEmptyLine = false
    var pastOpeningBreak = (params.fold == .foldFlow)
    var emptyLine = false
    var moreIndented = false
    var foldedNewlineCount = 0
    var foldedNewlineStartedMoreIndented = false
    var lastEscapedChar: Int? = nil
    var scalar = ""
    params.leadingSpaces = false

    let endPattern = params.end ?? Pattern.empty()

    while input.isValid {
        // Phase 1: scan until line ending
        var lastNonWhitespacePos = scalar.count
        var escapedNewline = false

        while !endPattern.matches(StreamReader(input)) && !Pattern.breakChar().matches(StreamReader(input)) {
            if !input.isValid { break }

            // Document indicator?
            if input.column == 0 && Pattern.docIndicator().matches(StreamReader(input)) {
                if params.onDocIndicator == .break { break }
                if params.onDocIndicator == .throw {
                    throw YAMLError.parser(mark: input.mark, message: ErrorMsg.DOC_IN_SCALAR)
                }
            }

            foundNonEmptyLine = true
            pastOpeningBreak = true

            // Escaped newline?
            if params.escape == UInt8(ascii: "\\") && Pattern.escBreak().matches(StreamReader(input)) {
                input.eat(1) // eat escape char
                lastNonWhitespacePos = scalar.count
                lastEscapedChar = scalar.count
                escapedNewline = true
                break
            }

            // Escape?
            if input.peek() == params.escape && params.escape != 0 {
                let escaped = try Pattern.escape(input)
                scalar += escaped
                lastNonWhitespacePos = scalar.count
                lastEscapedChar = scalar.count
                continue
            }

            // Regular character
            let nextByte = input.peek()
            if nextByte >= 0x80 {
                // Multi-byte UTF-8 character
                let ch = input.getChar()
                scalar.append(ch)
                lastNonWhitespacePos = scalar.count
            } else {
                let ch = input.get()
                scalar.append(Character(UnicodeScalar(ch)))
                if ch != UInt8(ascii: " ") && ch != UInt8(ascii: "\t") {
                    lastNonWhitespacePos = scalar.count
                }
            }
        }

        // EOF?
        if !input.isValid {
            if params.eatEnd {
                throw YAMLError.parser(mark: input.mark, message: ErrorMsg.EOF_IN_SCALAR)
            }
            break
        }

        // Doc indicator?
        if params.onDocIndicator == .break && input.column == 0 && Pattern.docIndicator().matches(StreamReader(input)) {
            break
        }

        // Character match end?
        let n = endPattern.match(StreamReader(input))
        if n >= 0 {
            if params.eatEnd { input.eat(n) }
            break
        }

        // Remove trailing whitespace for flow fold
        if params.fold == .foldFlow {
            let idx = scalar.index(scalar.startIndex, offsetBy: lastNonWhitespacePos)
            scalar = String(scalar[..<idx])
        }

        // Phase 2: eat line ending
        let breakLen = Pattern.breakChar().match(StreamReader(input))
        if breakLen > 0 { input.eat(breakLen) }

        // Phase 3: scan initial spaces
        while input.peek() == UInt8(ascii: " ") &&
              (input.column < params.indent || (params.detectIndent && !foundNonEmptyLine)) &&
              !(endPattern.match(StreamReader(input)) >= 0) {
            input.eat(1)
        }

        // Auto-detect indent
        if params.detectIndent && !foundNonEmptyLine {
            params.indent = max(params.indent, input.column)
        }

        // Eat remaining whitespace
        while Pattern.blank().matches(StreamReader(input)) {
            if input.peek() == UInt8(ascii: "\t") && input.column < params.indent && params.onTabInIndentation == .throw {
                throw YAMLError.parser(mark: input.mark, message: ErrorMsg.TAB_IN_INDENTATION)
            }
            if !params.eatLeadingWhitespace { break }
            if endPattern.match(StreamReader(input)) >= 0 { break }
            input.eat(1)
        }

        let nextEmptyLine = Pattern.breakChar().matches(StreamReader(input))
        let nextMoreIndented = Pattern.blank().matches(StreamReader(input))
        if params.fold == .foldBlock && foldedNewlineCount == 0 && nextEmptyLine {
            foldedNewlineStartedMoreIndented = moreIndented
        }

        if pastOpeningBreak {
            switch params.fold {
            case .dontFold:
                scalar += "\n"
            case .foldBlock:
                if !emptyLine && !nextEmptyLine && !moreIndented && !nextMoreIndented && input.column >= params.indent {
                    scalar += " "
                } else if nextEmptyLine {
                    foldedNewlineCount += 1
                } else {
                    scalar += "\n"
                }
                if !nextEmptyLine && foldedNewlineCount > 0 {
                    scalar += String(repeating: "\n", count: foldedNewlineCount - 1)
                    if foldedNewlineStartedMoreIndented || nextMoreIndented || !foundNonEmptyLine {
                        scalar += "\n"
                    }
                    foldedNewlineCount = 0
                }
            case .foldFlow:
                if nextEmptyLine {
                    scalar += "\n"
                } else if !emptyLine && !escapedNewline {
                    scalar += " "
                }
            }
        }

        emptyLine = nextEmptyLine
        moreIndented = nextMoreIndented
        pastOpeningBreak = true

        // Done via indentation?
        if !emptyLine && input.column < params.indent {
            params.leadingSpaces = true
            break
        }
    }

    // Post-processing: trim trailing spaces
    if params.trimTrailingSpaces {
        var pos = scalar.count
        while pos > 0 {
            let idx = scalar.index(scalar.startIndex, offsetBy: pos - 1)
            let ch = scalar[idx]
            if ch != " " && ch != "\t" { break }
            pos -= 1
        }
        if let esc = lastEscapedChar, pos < esc { pos = esc }
        if pos < scalar.count {
            scalar = String(scalar.prefix(pos))
        }
    }

    // Chomp
    switch params.chomp {
    case .clip:
        while scalar.hasSuffix("\n\n") {
            scalar.removeLast()
        }
    case .strip:
        while scalar.hasSuffix("\n") {
            if let esc = lastEscapedChar, scalar.count - 1 < esc { break }
            scalar.removeLast()
        }
    case .keep:
        break
    }

    return scalar
}
