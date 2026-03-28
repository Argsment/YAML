//
//  TokenType.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public enum TokenType: Sendable {
    case directive
    case docStart
    case docEnd
    case blockSeqStart
    case blockMapStart
    case blockEnd
    case blockEntry
    case flowSeqStart
    case flowMapStart
    case flowSeqEnd
    case flowMapEnd
    case flowEntry
    case key
    case value
    case anchor
    case alias
    case tag
    case plainScalar
    case nonPlainScalar
}

public struct Token: Sendable {
    public var type: TokenType
    public var mark: Mark
    public var value: String
    public var params: [String]
    public var data: Int

    public init(_ type: TokenType, _ mark: Mark) {
        self.type = type
        self.mark = mark
        self.value = ""
        self.params = []
        self.data = 0
    }
}
