//
//  Scanner.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

final class Scanner {
    let input: Stream
    var tokens: [Token] = []
    var tokenIndex: Int = 0
    var startedStream: Bool = false
    var endedStream: Bool = false
    var simpleKeyAllowed: Bool = true
    var scalarValueAllowed: Bool = false
    var canBeJSONFlow: Bool = false
    var simpleKeys: [SimpleKey] = []
    var indents: [IndentMarker] = []
    var indentRefs: [Int] = []
    var flows: [FlowMarker] = []

    init(_ input: String) {
        self.input = Stream(input)
    }

    var isEmpty: Bool {
        ensureTokensInQueue()
        return tokenIndex >= tokens.count
    }

    func peek() -> Token {
        ensureTokensInQueue()
        if tokenIndex < tokens.count {
            return tokens[tokenIndex]
        }
        return Token(.docEnd, input.mark)
    }

    @discardableResult
    func pop() -> Token {
        ensureTokensInQueue()
        let token = tokens[tokenIndex]
        tokenIndex += 1
        return token
    }

    func mark() -> Mark {
        return input.mark
    }

    private func ensureTokensInQueue() {
        while !endedStream {
            if tokenIndex < tokens.count && !needsMoreScanning() {
                break
            }
            scanNextToken()
        }
    }

    private func needsMoreScanning() -> Bool {
        // If there's a pending simple key that could affect the token
        // at the current position, we need to keep scanning to resolve it
        for key in simpleKeys {
            if key.tokenIndex >= tokenIndex {
                // There's a simple key registered at or after the current
                // consumption point - scan ahead to resolve it
                return true
            }
        }
        return false
    }

    func push(_ token: Token) {
        tokens.append(token)
    }

    // Context checks
    var isInFlowContext: Bool { !flows.isEmpty }
    var isInBlockContext: Bool { flows.isEmpty }

    var topIndent: Int {
        if indents.isEmpty { return -1 }
        return indents.last!.column
    }
}

// MARK: - Flow and Indent markers

enum FlowMarker {
    case flowSeq
    case flowMap
}

struct SimpleKey {
    var mark: Mark
    var tokenIndex: Int
    var isRequired: Bool

    init(mark: Mark, tokenIndex: Int, isRequired: Bool = false) {
        self.mark = mark
        self.tokenIndex = tokenIndex
        self.isRequired = isRequired
    }
}

struct IndentMarker {
    enum IndentType {
        case seq
        case map
    }

    var column: Int
    var type: IndentType
    var tokenIndex: Int

    init(column: Int, type: IndentType, tokenIndex: Int) {
        self.column = column
        self.type = type
        self.tokenIndex = tokenIndex
    }
}
