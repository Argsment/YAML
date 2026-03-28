//
//  NodeData.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

final class NodeData {
    var isDefined: Bool = false
    var mark: Mark = .null
    var type: NodeType = .null
    var tag: String = ""
    var style: EmitterStyle = .default
    var scalar: String = ""
    var sequence: [NodeData] = []
    var map: [(key: NodeData, value: NodeData)] = []

    init() {}

    func markDefined() {
        if type == .undefined { type = .null }
        isDefined = true
    }

    func setType(_ newType: NodeType) {
        if newType == .undefined {
            type = .undefined
            isDefined = false
            return
        }
        isDefined = true
        if newType == type { return }
        type = newType
        switch type {
        case .scalar: scalar = ""
        case .sequence: sequence = []
        case .map: map = []
        default: break
        }
    }

    func setNull() {
        isDefined = true
        type = .null
    }

    func setScalar(_ value: String) {
        isDefined = true
        type = .scalar
        scalar = value
    }

    var size: Int {
        guard isDefined else { return 0 }
        switch type {
        case .sequence: return sequence.count
        case .map: return map.count
        default: return 0
        }
    }

    func pushBack(_ node: NodeData) {
        if type == .undefined || type == .null {
            type = .sequence
            sequence = []
        }
        guard type == .sequence else { return }
        sequence.append(node)
    }

    func insert(key: NodeData, value: NodeData) {
        switch type {
        case .map: break
        case .undefined, .null, .sequence:
            convertToMap()
        case .scalar: return
        }
        map.append((key: key, value: value))
    }

    func get(key: NodeData) -> NodeData? {
        guard type == .map else { return nil }
        for entry in map {
            if entry.key === key || entry.key.scalar == key.scalar {
                return entry.value
            }
        }
        return nil
    }

    func getOrCreate(key: NodeData) -> NodeData {
        if let existing = get(key: key) { return existing }
        let value = NodeData()
        insert(key: key, value: value)
        return value
    }

    func remove(key: NodeData) -> Bool {
        guard type == .map else { return false }
        if let idx = map.firstIndex(where: { $0.key === key || $0.key.scalar == key.scalar }) {
            map.remove(at: idx)
            return true
        }
        return false
    }

    private func convertToMap() {
        switch type {
        case .sequence:
            let oldSeq = sequence
            map = []
            for (i, item) in oldSeq.enumerated() {
                let key = NodeData()
                key.setScalar("\(i)")
                map.append((key: key, value: item))
            }
            sequence = []
        default:
            map = []
        }
        type = .map
    }
}
