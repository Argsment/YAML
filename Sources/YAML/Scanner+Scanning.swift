//
//  ScannerImpl.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

extension Scanner {
    func scanNextToken() {
        if !startedStream {
            startedStream = true
            return
        }

        scanToNextToken()

        guard input.isValid else {
            endedStream = true
            popAllIndents()
            popAllSimpleKeys()
            return
        }

        // Stale simple keys
        stallSimpleKeys()

        // What indent level?
        unwindIndent(input.column)

        let ch = input.peek()

        do {
            // Special characters
            if ch == 0 { endedStream = true; return }

            if input.column == 0 && ch == UInt8(ascii: "%") {
                scanDirective()
                return
            }

            if input.column == 0 && input.isValid {
                let src = StreamReader(input)
                if Pattern.docIndicator().matches(src) {
                    // Check if it's --- or ...
                    if input.peek() == UInt8(ascii: "-") {
                        scanDocStart()
                    } else {
                        scanDocEnd()
                    }
                    return
                }
            }

            if ch == YAMLCharacter.flowSeqStart || ch == YAMLCharacter.flowMapStart {
                scanFlowStart()
                return
            }

            if ch == YAMLCharacter.flowSeqEnd || ch == YAMLCharacter.flowMapEnd {
                try scanFlowEnd()
                return
            }

            if ch == YAMLCharacter.flowEntry {
                scanFlowEntry()
                return
            }

            if ch == UInt8(ascii: "-") && !isInFlowContext {
                let src = StreamReader(input, offset: 1)
                if Pattern.blankOrBreak().matches(src) || !input.readAheadTo(1) {
                    try scanBlockEntry()
                    return
                }
            }

            if ch == UInt8(ascii: "?") && (isInFlowContext || Pattern.blankOrBreak().matches(StreamReader(input, offset: 1)) || !input.readAheadTo(1)) {
                try scanKey()
                return
            }

            if ch == UInt8(ascii: ":") && (isInFlowContext ? (canBeJSONFlow || Pattern.blankOrBreak().matches(StreamReader(input, offset: 1)) || !input.readAheadTo(1)) : (Pattern.blankOrBreak().matches(StreamReader(input, offset: 1)) || !input.readAheadTo(1))) {
                try scanValue()
                return
            }

            if ch == YAMLCharacter.alias || ch == YAMLCharacter.anchor {
                try scanAnchorOrAlias()
                return
            }

            if ch == YAMLCharacter.tag {
                try scanTag()
                return
            }

            if ch == UInt8(ascii: "|") || ch == UInt8(ascii: ">") {
                if isInBlockContext {
                    try scanBlockScalar()
                    return
                }
            }

            if ch == UInt8(ascii: "'") || ch == UInt8(ascii: "\"") {
                try scanQuotedScalar()
                return
            }

            // Plain scalar
            try scanPlainScalar()

        } catch {
            endedStream = true
            // Re-throw parsing errors
            // In the original C++, exceptions propagate. Here we store them.
            // For now, we'll just stop scanning.
        }
    }

    func scanToNextToken() {
        while true {
            // Eat whitespace
            while input.isValid && Pattern.blank().matches(StreamReader(input)) {
                input.eat(1)
            }

            // Comment?
            if Pattern.comment().matches(StreamReader(input)) {
                while input.isValid && !Pattern.breakChar().matches(StreamReader(input)) {
                    input.eat(1)
                }
            }

            // Line break?
            if Pattern.breakChar().matches(StreamReader(input)) {
                input.eat(1)
                if !isInFlowContext {
                    simpleKeyAllowed = true
                }
            } else {
                break
            }
        }
    }

    func stallSimpleKeys() {
        // Remove stale simple keys - keys on a different line than current
        // position in block context are no longer valid
        simpleKeys.removeAll { key in
            isInBlockContext && key.mark.line < input.line
        }
    }

    func pushIndentTo(_ column: Int, type: IndentMarker.IndentType) {
        if !isInBlockContext { return }
        if !indents.isEmpty && indents.last!.column >= column { return }

        let marker = IndentMarker(column: column, type: type, tokenIndex: tokens.count)
        indents.append(marker)

        let tokenType: TokenType = (type == .seq) ? .blockSeqStart : .blockMapStart
        push(Token(tokenType, input.mark))
    }

    func popIndent() {
        guard !indents.isEmpty else { return }
        indents.removeLast()
        push(Token(.blockEnd, input.mark))
    }

    func popAllIndents() {
        while !indents.isEmpty {
            popIndent()
        }
    }

    func unwindIndent(_ column: Int) {
        if isInFlowContext { return }
        while !indents.isEmpty && indents.last!.column > column {
            popIndent()
        }
    }
}
