//
//  Exceptions.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public enum ErrorMsg {
    public static let YAML_DIRECTIVE_ARGS = "YAML directives must have exactly one argument"
    public static let YAML_VERSION = "bad YAML version: "
    public static let YAML_MAJOR_VERSION = "YAML major version too large"
    public static let REPEATED_YAML_DIRECTIVE = "repeated YAML directive"
    public static let TAG_DIRECTIVE_ARGS = "TAG directives must have exactly two arguments"
    public static let REPEATED_TAG_DIRECTIVE = "repeated TAG directive"
    public static let CHAR_IN_TAG_HANDLE = "illegal character found while scanning tag handle"
    public static let TAG_WITH_NO_SUFFIX = "tag handle with no suffix"
    public static let END_OF_VERBATIM_TAG = "end of verbatim tag not found"
    public static let END_OF_MAP = "end of map not found"
    public static let END_OF_MAP_FLOW = "end of map flow not found"
    public static let END_OF_SEQ = "end of sequence not found"
    public static let END_OF_SEQ_FLOW = "end of sequence flow not found"
    public static let MULTIPLE_TAGS = "cannot assign multiple tags to the same node"
    public static let MULTIPLE_ANCHORS = "cannot assign multiple anchors to the same node"
    public static let MULTIPLE_ALIASES = "cannot assign multiple aliases to the same node"
    public static let ALIAS_CONTENT = "aliases can't have any content, *including* tags"
    public static let INVALID_HEX = "bad character found while scanning hex number"
    public static let INVALID_UNICODE = "invalid unicode: "
    public static let INVALID_ESCAPE = "unknown escape character: "
    public static let UNKNOWN_TOKEN = "unknown token"
    public static let DOC_IN_SCALAR = "illegal document indicator in scalar"
    public static let EOF_IN_SCALAR = "illegal EOF in scalar"
    public static let CHAR_IN_SCALAR = "illegal character in scalar"
    public static let UNEXPECTED_SCALAR = "unexpected scalar"
    public static let UNEXPECTED_FLOW = "plain value cannot start with flow indicator character"
    public static let TAB_IN_INDENTATION = "illegal tab when looking for indentation"
    public static let FLOW_END = "illegal flow end"
    public static let BLOCK_ENTRY = "illegal block entry"
    public static let MAP_KEY = "illegal map key"
    public static let MAP_VALUE = "illegal map value"
    public static let ALIAS_NOT_FOUND = "alias not found after *"
    public static let ANCHOR_NOT_FOUND = "anchor not found after &"
    public static let CHAR_IN_ALIAS = "illegal character found while scanning alias"
    public static let CHAR_IN_ANCHOR = "illegal character found while scanning anchor"
    public static let ZERO_INDENT_IN_BLOCK = "cannot set zero indentation for a block scalar"
    public static let CHAR_IN_BLOCK = "unexpected character in block scalar"
    public static let AMBIGUOUS_ANCHOR = "cannot assign the same alias to multiple nodes"
    public static let UNKNOWN_ANCHOR = "the referenced anchor is not defined: "
    public static let INVALID_NODE = "invalid node; this may result from using a map iterator as a sequence iterator, or vice-versa"
    public static let INVALID_SCALAR = "invalid scalar"
    public static let KEY_NOT_FOUND = "key not found"
    public static let BAD_CONVERSION = "bad conversion"
    public static let BAD_DEREFERENCE = "bad dereference"
    public static let BAD_SUBSCRIPT = "operator[] call on a scalar"
    public static let BAD_PUSHBACK = "appending to a non-sequence"
    public static let BAD_INSERT = "inserting in a non-convertible-to-map"
    public static let UNMATCHED_GROUP_TAG = "unmatched group tag"
    public static let UNEXPECTED_END_SEQ = "unexpected end sequence token"
    public static let UNEXPECTED_END_MAP = "unexpected end map token"
    public static let SINGLE_QUOTED_CHAR = "invalid character in single-quoted string"
    public static let INVALID_ANCHOR = "invalid anchor"
    public static let INVALID_ALIAS = "invalid alias"
    public static let INVALID_TAG = "invalid tag"
    public static let BAD_FILE = "bad file"
    public static let UNEXPECTED_TOKEN_AFTER_DOC = "unexpected token after end of document"
    public static let NON_UNIQUE_MAP_KEY = "map keys must be unique"
}

public enum YAMLError: Error, CustomStringConvertible {
    case parser(mark: Mark, message: String)
    case representation(mark: Mark, message: String)
    case emitter(message: String)
    case badFile(filename: String)
    case deepRecursion(depth: Int, mark: Mark, message: String)
    case invalidScalar(mark: Mark)
    case keyNotFound(mark: Mark, message: String)
    case invalidNode(key: String)
    case badConversion(mark: Mark)
    case badDereference
    case badSubscript(mark: Mark, message: String)
    case badPushback
    case badInsert
    case nonUniqueMapKey(mark: Mark)

    public var description: String {
        switch self {
        case .parser(let mark, let msg):
            return buildWhat(mark: mark, msg: msg)
        case .representation(let mark, let msg):
            return buildWhat(mark: mark, msg: msg)
        case .emitter(let msg):
            return msg
        case .badFile(let filename):
            return "\(ErrorMsg.BAD_FILE): \(filename)"
        case .deepRecursion(_, let mark, let msg):
            return buildWhat(mark: mark, msg: msg)
        case .invalidScalar(let mark):
            return buildWhat(mark: mark, msg: ErrorMsg.INVALID_SCALAR)
        case .keyNotFound(let mark, let msg):
            return buildWhat(mark: mark, msg: msg)
        case .invalidNode(let key):
            if key.isEmpty { return ErrorMsg.INVALID_NODE }
            return "invalid node; first invalid key: \"\(key)\""
        case .badConversion(let mark):
            return buildWhat(mark: mark, msg: ErrorMsg.BAD_CONVERSION)
        case .badDereference:
            return ErrorMsg.BAD_DEREFERENCE
        case .badSubscript(let mark, let msg):
            return buildWhat(mark: mark, msg: msg)
        case .badPushback:
            return ErrorMsg.BAD_PUSHBACK
        case .badInsert:
            return ErrorMsg.BAD_INSERT
        case .nonUniqueMapKey(let mark):
            return buildWhat(mark: mark, msg: ErrorMsg.NON_UNIQUE_MAP_KEY)
        }
    }

    private func buildWhat(mark: Mark, msg: String) -> String {
        if mark.isNull {
            return msg
        }
        return "yaml-cpp: error at line \(mark.line + 1), column \(mark.column + 1): \(msg)"
    }
}
