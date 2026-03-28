//
//  NodeBuilder.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

final class NodeBuilder: EventHandler {
    private var root: NodeData?
    private var stack: [NodeData] = []
    private var anchors: [NodeData?] = [nil] // anchors start at 1
    private var keys: [(node: NodeData, used: Bool)] = []
    private var mapDepth: Int = 0

    func rootNode() -> Node {
        guard let root = root else { return Node() }
        return Node(root)
    }

    func onDocumentStart(_ mark: Mark) {}
    func onDocumentEnd() {}

    func onNull(_ mark: Mark, anchor: AnchorID) {
        let node = push(mark: mark, anchor: anchor)
        node.setNull()
        pop()
    }

    func onAlias(_ mark: Mark, anchor: AnchorID) {
        guard anchor > 0 && anchor < anchors.count, let node = anchors[anchor] else { return }
        pushExisting(node)
        pop()
    }

    func onScalar(_ mark: Mark, tag: String, anchor: AnchorID, value: String) {
        let node = push(mark: mark, anchor: anchor)
        node.setScalar(value)
        node.tag = tag
        pop()
    }

    func onSequenceStart(_ mark: Mark, tag: String, anchor: AnchorID, style: EmitterStyle) {
        let node = push(mark: mark, anchor: anchor)
        node.tag = tag
        node.setType(.sequence)
        node.style = style
    }

    func onSequenceEnd() { pop() }

    func onMapStart(_ mark: Mark, tag: String, anchor: AnchorID, style: EmitterStyle) {
        let node = push(mark: mark, anchor: anchor)
        node.setType(.map)
        node.tag = tag
        node.style = style
        mapDepth += 1
    }

    func onMapEnd() {
        mapDepth -= 1
        pop()
    }

    @discardableResult
    private func push(mark: Mark, anchor: AnchorID) -> NodeData {
        let node = NodeData()
        node.mark = mark
        node.markDefined()
        registerAnchor(anchor, node)
        pushExisting(node)
        return node
    }

    private func pushExisting(_ node: NodeData) {
        let needsKey = !stack.isEmpty && stack.last!.type == .map && keys.count < mapDepth
        stack.append(node)
        if needsKey {
            keys.append((node: node, used: false))
        }
    }

    private func pop() {
        guard !stack.isEmpty else { return }

        if stack.count == 1 {
            root = stack[0]
            stack.removeLast()
            return
        }

        let node = stack.removeLast()
        let collection = stack.last!

        if collection.type == .sequence {
            collection.pushBack(node)
        } else if collection.type == .map {
            guard !keys.isEmpty else { return }
            if keys.last!.used {
                collection.insert(key: keys.last!.node, value: node)
                keys.removeLast()
            } else {
                keys[keys.count - 1].used = true
            }
        }
    }

    private func registerAnchor(_ anchor: AnchorID, _ node: NodeData) {
        if anchor != nullAnchor {
            while anchors.count <= anchor {
                anchors.append(nil)
            }
            anchors[anchor] = node
        }
    }
}
