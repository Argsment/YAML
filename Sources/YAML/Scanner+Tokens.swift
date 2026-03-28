//
//  ScanToken.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

extension Scanner {
    func scanDirective() {
        popAllIndents()
        popAllSimpleKeys()
        simpleKeyAllowed = false
        canBeJSONFlow = false

        var token = Token(.directive, input.mark)
        input.eat(1) // eat '%'

        // Read name
        while input.isValid && !Pattern.blankOrBreak().matches(StreamReader(input)) {
            token.value.append(Character(UnicodeScalar(input.get())))
        }

        // Read parameters
        while true {
            while Pattern.blank().matches(StreamReader(input)) { input.eat(1) }
            if !input.isValid || Pattern.breakChar().matches(StreamReader(input)) || Pattern.comment().matches(StreamReader(input)) { break }
            var param = ""
            while input.isValid && !Pattern.blankOrBreak().matches(StreamReader(input)) {
                param.append(Character(UnicodeScalar(input.get())))
            }
            token.params.append(param)
        }

        push(token)
    }

    func scanDocStart() {
        popAllIndents()
        popAllSimpleKeys()
        simpleKeyAllowed = false
        canBeJSONFlow = false
        let mark = input.mark
        input.eat(3)
        push(Token(.docStart, mark))
    }

    func scanDocEnd() {
        popAllIndents()
        popAllSimpleKeys()
        simpleKeyAllowed = false
        canBeJSONFlow = false
        let mark = input.mark
        input.eat(3)
        push(Token(.docEnd, mark))
    }

    func scanFlowStart() {
        insertPotentialSimpleKey()
        simpleKeyAllowed = true
        canBeJSONFlow = false

        let mark = input.mark
        let ch = input.get()
        let flowType: FlowMarker = (ch == YAMLCharacter.flowSeqStart) ? .flowSeq : .flowMap
        flows.append(flowType)
        let type: TokenType = (flowType == .flowSeq) ? .flowSeqStart : .flowMapStart
        push(Token(type, mark))
    }

    func scanFlowEnd() throws {
        guard isInFlowContext else {
            throw YAMLError.parser(mark: input.mark, message: ErrorMsg.FLOW_END)
        }

        if isInFlowContext {
            if flows.last == .flowMap && verifySimpleKey() {
                push(Token(.value, input.mark))
            } else if flows.last == .flowSeq {
                invalidateSimpleKey()
            }
        }

        simpleKeyAllowed = false
        canBeJSONFlow = true

        let mark = input.mark
        let ch = input.get()
        let flowType: FlowMarker = (ch == YAMLCharacter.flowSeqEnd) ? .flowSeq : .flowMap

        guard flows.last == flowType else {
            throw YAMLError.parser(mark: mark, message: ErrorMsg.FLOW_END)
        }
        flows.removeLast()

        let type: TokenType = (flowType == .flowSeq) ? .flowSeqEnd : .flowMapEnd
        push(Token(type, mark))
    }

    func scanFlowEntry() {
        if isInFlowContext {
            if flows.last == .flowMap && verifySimpleKey() {
                push(Token(.value, input.mark))
            } else if flows.last == .flowSeq {
                invalidateSimpleKey()
            }
        }

        simpleKeyAllowed = true
        canBeJSONFlow = false

        let mark = input.mark
        input.eat(1)
        push(Token(.flowEntry, mark))
    }

    func scanBlockEntry() throws {
        guard isInBlockContext else {
            throw YAMLError.parser(mark: input.mark, message: ErrorMsg.BLOCK_ENTRY)
        }
        guard simpleKeyAllowed else {
            throw YAMLError.parser(mark: input.mark, message: ErrorMsg.BLOCK_ENTRY)
        }

        pushIndentTo(input.column, type: .seq)
        simpleKeyAllowed = true
        canBeJSONFlow = false

        let mark = input.mark
        input.eat(1)
        push(Token(.blockEntry, mark))
    }

    func scanKey() throws {
        if isInBlockContext {
            guard simpleKeyAllowed else {
                throw YAMLError.parser(mark: input.mark, message: ErrorMsg.MAP_KEY)
            }
            pushIndentTo(input.column, type: .map)
        }

        simpleKeyAllowed = isInBlockContext

        let mark = input.mark
        input.eat(1)
        push(Token(.key, mark))
    }

    func scanValue() throws {
        let isSimpleKey = verifySimpleKey()
        canBeJSONFlow = false

        if isSimpleKey {
            simpleKeyAllowed = false
        } else {
            if isInBlockContext {
                guard simpleKeyAllowed else {
                    throw YAMLError.parser(mark: input.mark, message: ErrorMsg.MAP_VALUE)
                }
                pushIndentTo(input.column, type: .map)
            }
            simpleKeyAllowed = isInBlockContext
        }

        scalarValueAllowed = true

        let mark = input.mark
        input.eat(1)
        push(Token(.value, mark))
    }

    func scanAnchorOrAlias() throws {
        insertPotentialSimpleKey()
        simpleKeyAllowed = false
        canBeJSONFlow = false

        let mark = input.mark
        let indicator = input.get()
        let isAlias = (indicator == YAMLCharacter.alias)

        var name = ""
        while input.isValid && Pattern.anchor().matches(StreamReader(input)) {
            name.append(Character(UnicodeScalar(input.get())))
        }

        guard !name.isEmpty else {
            throw YAMLError.parser(mark: input.mark, message: isAlias ? ErrorMsg.ALIAS_NOT_FOUND : ErrorMsg.ANCHOR_NOT_FOUND)
        }

        if input.isValid && !Pattern.anchorEnd().matches(StreamReader(input)) && !Pattern.blankOrBreak().matches(StreamReader(input)) {
            throw YAMLError.parser(mark: input.mark, message: isAlias ? ErrorMsg.CHAR_IN_ALIAS : ErrorMsg.CHAR_IN_ANCHOR)
        }

        var token = Token(isAlias ? .alias : .anchor, mark)
        token.value = name
        push(token)
    }

    func scanTag() throws {
        insertPotentialSimpleKey()
        simpleKeyAllowed = false
        canBeJSONFlow = false

        var token = Token(.tag, input.mark)
        input.eat(1) // eat '!'

        if input.isValid && input.peek() == YAMLCharacter.verbatimTagStart {
            let tag = try scanVerbatimTag(input)
            token.value = tag
            token.data = Tag.TagType.verbatim.rawValue
        } else {
            var canBeHandle = false
            token.value = scanTagHandle(input, canBeHandle: &canBeHandle)
            if !canBeHandle && token.value.isEmpty {
                token.data = Tag.TagType.nonSpecific.rawValue
            } else if token.value.isEmpty {
                token.data = Tag.TagType.secondaryHandle.rawValue
            } else {
                token.data = Tag.TagType.primaryHandle.rawValue
            }

            // Check for suffix
            if canBeHandle && input.isValid && input.peek() == YAMLCharacter.tag {
                input.eat(1)
                token.params.append(scanTagSuffix(input))
                token.data = Tag.TagType.namedHandle.rawValue
            }
        }

        push(token)
    }

    func scanPlainScalar() throws {
        var params = ScanScalarParams()
        params.end = isInFlowContext ? Pattern.scanScalarEndInFlow() : Pattern.scanScalarEnd()
        params.eatEnd = false
        params.indent = isInFlowContext ? 0 : topIndent + 1
        params.fold = .foldFlow
        params.eatLeadingWhitespace = true
        params.trimTrailingSpaces = true
        params.chomp = .strip
        params.onDocIndicator = .break
        params.onTabInIndentation = .throw

        insertPotentialSimpleKey()

        let mark = input.mark
        let scalar = try scanScalar(input, &params)

        simpleKeyAllowed = params.leadingSpaces
        canBeJSONFlow = false

        var token = Token(.plainScalar, mark)
        token.value = scalar
        push(token)
    }

    func scanQuotedScalar() throws {
        let quote = input.peek()
        let single = (quote == UInt8(ascii: "'"))

        var params = ScanScalarParams()
        let end = single ? (PatternMatcher(char: "'") & !Pattern.escSingleQuote()) : PatternMatcher(char: "\"")
        params.end = end
        params.eatEnd = true
        params.escape = single ? UInt8(ascii: "'") : UInt8(ascii: "\\")
        params.indent = 0
        params.fold = .foldFlow
        params.eatLeadingWhitespace = true
        params.trimTrailingSpaces = false
        params.chomp = .clip
        params.onDocIndicator = .throw

        insertPotentialSimpleKey()

        let mark = input.mark
        input.eat(1) // eat opening quote

        let scalar = try scanScalar(input, &params)
        simpleKeyAllowed = false
        scalarValueAllowed = isInFlowContext
        canBeJSONFlow = true

        var token = Token(.nonPlainScalar, mark)
        token.value = scalar
        push(token)
    }

    func scanBlockScalar() throws {
        var params = ScanScalarParams()
        params.indent = 1
        params.detectIndent = true

        let mark = input.mark
        let indicator = input.get()
        params.fold = (indicator == YAMLCharacter.foldedScalar) ? .foldBlock : .dontFold

        // Eat chomping/indentation indicators
        params.chomp = .clip
        let chompLen = Pattern.chomp().match(StreamReader(input))
        if chompLen > 0 {
            for _ in 0..<chompLen {
                let ch = input.get()
                if ch == UInt8(ascii: "+") { params.chomp = .keep }
                else if ch == UInt8(ascii: "-") { params.chomp = .strip }
                else if ch >= UInt8(ascii: "0") && ch <= UInt8(ascii: "9") {
                    guard ch != UInt8(ascii: "0") else {
                        throw YAMLError.parser(mark: input.mark, message: ErrorMsg.ZERO_INDENT_IN_BLOCK)
                    }
                    params.indent = Int(ch - UInt8(ascii: "0"))
                    params.detectIndent = false
                }
            }
        }

        // Eat whitespace
        while Pattern.blank().matches(StreamReader(input)) { input.eat(1) }

        // Comments to end of line
        if Pattern.comment().matches(StreamReader(input)) {
            while input.isValid && !Pattern.breakChar().matches(StreamReader(input)) { input.eat(1) }
        }

        // Should be line break
        if input.isValid && !Pattern.breakChar().matches(StreamReader(input)) {
            throw YAMLError.parser(mark: input.mark, message: ErrorMsg.CHAR_IN_BLOCK)
        }

        // Set initial indentation
        if topIndent >= 0 {
            params.indent += topIndent
        }

        params.eatLeadingWhitespace = false
        params.trimTrailingSpaces = false
        params.onTabInIndentation = .throw

        let scalar = try scanScalar(input, &params)

        simpleKeyAllowed = true
        canBeJSONFlow = false

        var token = Token(.nonPlainScalar, mark)
        token.value = scalar
        push(token)
    }
}
