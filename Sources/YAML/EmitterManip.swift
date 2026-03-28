//
//  EmitterManip.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public enum EmitterManip: Sendable {
    // general
    case auto_
    case tagByKind
    case newline
    // output charset
    case emitNonAscii
    case escapeNonAscii
    case escapeAsJson
    // string format
    case singleQuoted
    case doubleQuoted
    case literal
    // null format
    case lowerNull
    case upperNull
    case camelNull
    case tildeNull
    // bool format
    case yesNoBool
    case trueFalseBool
    case onOffBool
    case upperCase
    case lowerCase
    case camelCase
    case longBool
    case shortBool
    // int format
    case dec
    case hex
    case oct
    // document
    case beginDoc
    case endDoc
    // sequence
    case beginSeq
    case endSeq
    case flow
    case block
    // map
    case beginMap
    case endMap
    case key
    case value
    case longKey
}

public struct Indent: Sendable {
    public let value: Int
    public init(_ value: Int) { self.value = value }
}

public struct Alias: Sendable {
    public let content: String
    public init(_ content: String) { self.content = content }
}

public struct AnchorManip: Sendable {
    public let content: String
    public init(_ content: String) { self.content = content }
}

public struct TagManip: Sendable {
    public enum TagType: Sendable {
        case verbatim
        case primaryHandle
        case namedHandle
    }

    public let prefix: String
    public let content: String
    public let type: TagType

    public init(prefix: String = "", content: String, type: TagType) {
        self.prefix = prefix
        self.content = content
        self.type = type
    }
}

public func verbatimTag(_ content: String) -> TagManip {
    TagManip(content: content, type: .verbatim)
}

public func localTag(_ content: String) -> TagManip {
    TagManip(content: content, type: .primaryHandle)
}

public func localTag(prefix: String, _ content: String) -> TagManip {
    TagManip(prefix: prefix, content: content, type: .namedHandle)
}

public func secondaryTag(_ content: String) -> TagManip {
    TagManip(content: content, type: .namedHandle)
}

public struct Comment: Sendable {
    public let content: String
    public init(_ content: String) { self.content = content }
}

public struct Precision: Sendable {
    public let floatPrecision: Int
    public let doublePrecision: Int
    public init(float: Int = -1, double: Int = -1) {
        self.floatPrecision = float
        self.doublePrecision = double
    }
}

public func floatPrecision(_ n: Int) -> Precision { Precision(float: n) }
public func doublePrecision(_ n: Int) -> Precision { Precision(double: n) }
public func precision(_ n: Int) -> Precision { Precision(float: n, double: n) }
