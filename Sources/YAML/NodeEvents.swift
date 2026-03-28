//
//  NodeEvents.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

final class NodeEvents {
    private let root: NodeData?
    private var refCount: [ObjectIdentifier: Int] = [:]

    init(_ node: Node) {
        self.root = node.data
        if let root = root {
            setup(root)
        }
    }

    private func setup(_ node: NodeData) {
        let id = ObjectIdentifier(node)
        refCount[id, default: 0] += 1
        if refCount[id]! > 1 { return }

        if node.type == .sequence {
            for child in node.sequence { setup(child) }
        } else if node.type == .map {
            for entry in node.map {
                setup(entry.key)
                setup(entry.value)
            }
        }
    }

    func emit(_ handler: EventHandler) {
        var am = AliasManager()
        handler.onDocumentStart(Mark())
        if let root = root {
            emit(root, handler: handler, am: &am)
        }
        handler.onDocumentEnd()
    }

    private func emit(_ node: NodeData, handler: EventHandler, am: inout AliasManager) {
        var anchor: AnchorID = nullAnchor
        let id = ObjectIdentifier(node)

        if isAliased(node) {
            anchor = am.lookupAnchor(id)
            if anchor != nullAnchor {
                handler.onAlias(Mark(), anchor: anchor)
                return
            }
            am.registerReference(id)
            anchor = am.lookupAnchor(id)
        }

        switch node.type {
        case .undefined:
            break
        case .null:
            handler.onNull(node.mark, anchor: anchor)
        case .scalar:
            handler.onScalar(node.mark, tag: node.tag, anchor: anchor, value: node.scalar)
        case .sequence:
            handler.onSequenceStart(node.mark, tag: node.tag, anchor: anchor, style: node.style)
            for child in node.sequence {
                emit(child, handler: handler, am: &am)
            }
            handler.onSequenceEnd()
        case .map:
            handler.onMapStart(node.mark, tag: node.tag, anchor: anchor, style: node.style)
            for entry in node.map {
                emit(entry.key, handler: handler, am: &am)
                emit(entry.value, handler: handler, am: &am)
            }
            handler.onMapEnd()
        }
    }

    private func isAliased(_ node: NodeData) -> Bool {
        let id = ObjectIdentifier(node)
        return (refCount[id] ?? 0) > 1
    }

    struct AliasManager {
        private var anchors: [ObjectIdentifier: AnchorID] = [:]
        private var nextAnchor: AnchorID = 1

        mutating func registerReference(_ id: ObjectIdentifier) {
            anchors[id] = nextAnchor
            nextAnchor += 1
        }

        func lookupAnchor(_ id: ObjectIdentifier) -> AnchorID {
            anchors[id] ?? nullAnchor
        }
    }
}
