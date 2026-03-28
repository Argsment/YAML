//
//  SimpleKey.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

extension Scanner {
    func insertPotentialSimpleKey() {
        if !simpleKeyAllowed { return }
        let key = SimpleKey(mark: input.mark, tokenIndex: tokens.count)
        simpleKeys.append(key)
    }

    @discardableResult
    func verifySimpleKey() -> Bool {
        guard !simpleKeys.isEmpty else { return false }
        let key = simpleKeys.removeLast()

        // If the key points to a flow start token, it's for the outer
        // context and should not be verified inside the flow
        if key.tokenIndex < tokens.count {
            let targetType = tokens[key.tokenIndex].type
            if targetType == .flowMapStart || targetType == .flowSeqStart {
                return false
            }
        }

        var insertAt = key.tokenIndex
        var insertedCount = 0

        // Push block map indent for block context simple keys
        if isInBlockContext {
            if indents.isEmpty || indents.last!.column < key.mark.column {
                let marker = IndentMarker(column: key.mark.column, type: .map, tokenIndex: insertAt)
                indents.append(marker)
                let mapStartToken = Token(.blockMapStart, key.mark)
                tokens.insert(mapStartToken, at: insertAt)
                insertAt += 1
                insertedCount += 1
            }
        }

        // Insert a KEY token before the simple key value
        let keyToken = Token(.key, key.mark)
        tokens.insert(keyToken, at: insertAt)
        insertedCount += 1

        // Adjust tokenIndex since we inserted before the current position
        if tokenIndex > key.tokenIndex {
            tokenIndex += insertedCount
        }

        return true
    }

    func invalidateSimpleKey() {
        if !simpleKeys.isEmpty {
            simpleKeys.removeLast()
        }
    }

    func popAllSimpleKeys() {
        simpleKeys.removeAll()
    }
}
