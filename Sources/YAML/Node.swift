//
//  Node.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public final class Node {
    var data: NodeData

    public init() {
        self.data = NodeData()
    }

    init(_ data: NodeData) {
        self.data = data
    }

    // Type checks
    public var isDefined: Bool { data.isDefined }
    public var isNull: Bool { data.type == .null }
    public var isScalar: Bool { data.type == .scalar }
    public var isSequence: Bool { data.type == .sequence }
    public var isMap: Bool { data.type == .map }
    public var type: NodeType { data.type }

    // Scalar access
    public var scalar: String { data.scalar }

    // Tag and style
    public var tag: String {
        get { data.tag }
        set { data.tag = newValue }
    }

    public var style: EmitterStyle {
        get { data.style }
        set { data.style = newValue }
    }

    public var mark: Mark { data.mark }

    // Size (for sequences and maps)
    public var size: Int { data.size }

    // Subscript by string key
    public subscript(key: String) -> Node {
        get {
            let keyNode = NodeData()
            keyNode.setScalar(key)
            if let existing = data.get(key: keyNode) {
                return Node(existing)
            }
            // Return undefined node
            let result = data.getOrCreate(key: keyNode)
            return Node(result)
        }
        set {
            let keyNode = NodeData()
            keyNode.setScalar(key)
            // Remove existing
            data.remove(key: keyNode)
            data.insert(key: keyNode, value: newValue.data)
        }
    }

    // Subscript by integer index
    public subscript(index: Int) -> Node {
        get {
            guard data.type == .sequence && index < data.sequence.count else {
                return Node()
            }
            return Node(data.sequence[index])
        }
    }

    // Append to sequence
    public func append(_ node: Node) {
        data.pushBack(node.data)
    }

    // Remove key
    @discardableResult
    public func remove(_ key: String) -> Bool {
        let keyNode = NodeData()
        keyNode.setScalar(key)
        return data.remove(key: keyNode)
    }

    // Reset to another node
    public func reset(_ other: Node) {
        data = other.data
    }

    // Set value
    public func set(_ value: String) {
        data.setScalar(value)
    }

    // Convert to various types
    public func `as`<T: LosslessStringConvertible>(_ type: T.Type) -> T? {
        guard data.type == .scalar else { return nil }
        return T(data.scalar)
    }

    public func `as`(_ type: String.Type) -> String? {
        guard data.type == .scalar else { return nil }
        return data.scalar
    }

    public func `as`(_ type: Bool.Type) -> Bool? {
        guard data.type == .scalar else { return nil }
        return convertToBool(data.scalar)
    }

    public func `as`(_ type: Int.Type) -> Int? {
        guard data.type == .scalar else { return nil }
        return Int(data.scalar)
    }

    public func `as`(_ type: Double.Type) -> Double? {
        guard data.type == .scalar else { return nil }
        return convertToDouble(data.scalar)
    }
}

// MARK: - Sequence conformance
extension Node: Sequence {
    public struct Iterator: IteratorProtocol {
        let node: Node
        var index: Int = 0
        var mapMode: Bool

        init(_ node: Node) {
            self.node = node
            self.mapMode = node.isMap
        }

        public mutating func next() -> Node? {
            if mapMode {
                guard index < node.data.map.count else { return nil }
                // Return key-value pairs as a 2-element sequence node
                let entry = node.data.map[index]
                index += 1
                let pair = Node()
                pair.data.setType(.sequence)
                pair.data.sequence = [entry.key, entry.value]
                return pair
            } else {
                guard node.data.type == .sequence && index < node.data.sequence.count else { return nil }
                let result = Node(node.data.sequence[index])
                index += 1
                return result
            }
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(self)
    }
}

// MARK: - Conversions

private func convertToBool(_ str: String) -> Bool? {
    let lower = str.lowercased()
    switch lower {
    case "y", "yes", "true", "on": return true
    case "n", "no", "false", "off": return false
    default: return nil
    }
}

private func convertToDouble(_ str: String) -> Double? {
    if str == ".inf" || str == ".Inf" || str == ".INF" || str == "+.inf" || str == "+.Inf" || str == "+.INF" {
        return Double.infinity
    }
    if str == "-.inf" || str == "-.Inf" || str == "-.INF" {
        return -Double.infinity
    }
    if str == ".nan" || str == ".NaN" || str == ".NAN" {
        return Double.nan
    }
    // Handle hex
    if str.hasPrefix("0x") || str.hasPrefix("0X") {
        return Double(UInt64(str.dropFirst(2), radix: 16) ?? 0)
    }
    // Handle octal
    if str.hasPrefix("0o") || str.hasPrefix("0O") {
        return Double(UInt64(str.dropFirst(2), radix: 8) ?? 0)
    }
    return Double(str)
}
