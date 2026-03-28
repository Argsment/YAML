//
//  SingleDocParser.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

final class SingleDocParser {
    private let scanner: Scanner
    private let directives: Directives
    private let collectionStack = CollectionStack()
    private var anchors: [String: AnchorID] = [:]
    private var curAnchor: AnchorID = 0
    private var depth: Int = 0
    private let depthCounter = DepthCounter()

    init(_ scanner: Scanner, _ directives: Directives) {
        self.scanner = scanner
        self.directives = directives
    }

    func handleDocument(_ eventHandler: EventHandler) throws {
        guard !scanner.isEmpty else { return }

        eventHandler.onDocumentStart(scanner.peek().mark)

        if scanner.peek().type == .docStart {
            scanner.pop()
        }

        try handleNode(eventHandler)

        eventHandler.onDocumentEnd()

        if !scanner.isEmpty && scanner.peek().type != .docEnd && scanner.peek().type != .docStart {
            throw YAMLError.parser(mark: scanner.mark(), message: ErrorMsg.UNEXPECTED_TOKEN_AFTER_DOC)
        }

        if !scanner.isEmpty && scanner.peek().type == .docEnd {
            scanner.pop()
        }
    }

    private func handleNode(_ eventHandler: EventHandler) throws {
        try withDepthGuard(counter: depthCounter, mark: scanner.mark(), message: ErrorMsg.BAD_FILE) {
            try self._handleNode(eventHandler)
        }
    }

    private func _handleNode(_ eventHandler: EventHandler) throws {
        if scanner.isEmpty {
            eventHandler.onNull(scanner.mark(), anchor: nullAnchor)
            return
        }

        let mark = scanner.peek().mark

        // Special case: value node by itself must be a map
        if scanner.peek().type == .value {
            eventHandler.onMapStart(mark, tag: "?", anchor: nullAnchor, style: .default)
            try handleMap(eventHandler)
            eventHandler.onMapEnd()
            return
        }

        // Alias node
        if scanner.peek().type == .alias {
            let anchor = try lookupAnchor(mark: mark, name: scanner.peek().value)
            eventHandler.onAlias(mark, anchor: anchor)
            scanner.pop()
            return
        }

        var tag = ""
        var anchorName = ""
        var anchor: AnchorID = nullAnchor
        parseProperties(&tag, &anchor, &anchorName)

        if !anchorName.isEmpty {
            eventHandler.onAnchor(mark, anchorName: anchorName)
        }

        if scanner.isEmpty {
            eventHandler.onNull(mark, anchor: anchor)
            return
        }

        let token = scanner.peek()

        if tag.isEmpty {
            tag = (token.type == .nonPlainScalar) ? "!" : "?"
        }

        if token.type == .plainScalar && tag == "?" && isNullString(token.value) {
            eventHandler.onNull(mark, anchor: anchor)
            scanner.pop()
            return
        }

        switch token.type {
        case .plainScalar, .nonPlainScalar:
            eventHandler.onScalar(mark, tag: tag, anchor: anchor, value: token.value)
            scanner.pop()
        case .flowSeqStart:
            eventHandler.onSequenceStart(mark, tag: tag, anchor: anchor, style: .flow)
            try handleSequence(eventHandler)
            eventHandler.onSequenceEnd()
        case .blockSeqStart:
            eventHandler.onSequenceStart(mark, tag: tag, anchor: anchor, style: .block)
            try handleSequence(eventHandler)
            eventHandler.onSequenceEnd()
        case .flowMapStart:
            eventHandler.onMapStart(mark, tag: tag, anchor: anchor, style: .flow)
            try handleMap(eventHandler)
            eventHandler.onMapEnd()
        case .blockMapStart:
            eventHandler.onMapStart(mark, tag: tag, anchor: anchor, style: .block)
            try handleMap(eventHandler)
            eventHandler.onMapEnd()
        case .key:
            if collectionStack.curCollectionType == .flowSeq {
                eventHandler.onMapStart(mark, tag: tag, anchor: anchor, style: .flow)
                try handleMap(eventHandler)
                eventHandler.onMapEnd()
            } else {
                if tag == "?" {
                    eventHandler.onNull(mark, anchor: anchor)
                } else {
                    eventHandler.onScalar(mark, tag: tag, anchor: anchor, value: "")
                }
            }
        default:
            if tag == "?" {
                eventHandler.onNull(mark, anchor: anchor)
            } else {
                eventHandler.onScalar(mark, tag: tag, anchor: anchor, value: "")
            }
        }
    }

    private func handleSequence(_ eventHandler: EventHandler) throws {
        switch scanner.peek().type {
        case .blockSeqStart:
            try handleBlockSequence(eventHandler)
        case .flowSeqStart:
            try handleFlowSequence(eventHandler)
        default:
            break
        }
    }

    private func handleBlockSequence(_ eventHandler: EventHandler) throws {
        scanner.pop()
        collectionStack.pushCollectionType(.blockSeq)

        while true {
            guard !scanner.isEmpty else {
                throw YAMLError.parser(mark: scanner.mark(), message: ErrorMsg.END_OF_SEQ)
            }

            let token = scanner.peek()
            guard token.type == .blockEntry || token.type == .blockEnd else {
                throw YAMLError.parser(mark: token.mark, message: ErrorMsg.END_OF_SEQ)
            }

            scanner.pop()
            if token.type == .blockEnd { break }

            if !scanner.isEmpty {
                let next = scanner.peek()
                if next.type == .blockEntry || next.type == .blockEnd {
                    eventHandler.onNull(next.mark, anchor: nullAnchor)
                    continue
                }
            }

            try handleNode(eventHandler)
        }

        collectionStack.popCollectionType(.blockSeq)
    }

    private func handleFlowSequence(_ eventHandler: EventHandler) throws {
        scanner.pop()
        collectionStack.pushCollectionType(.flowSeq)

        while true {
            guard !scanner.isEmpty else {
                throw YAMLError.parser(mark: scanner.mark(), message: ErrorMsg.END_OF_SEQ_FLOW)
            }

            if scanner.peek().type == .flowSeqEnd {
                scanner.pop()
                break
            }

            try handleNode(eventHandler)

            guard !scanner.isEmpty else {
                throw YAMLError.parser(mark: scanner.mark(), message: ErrorMsg.END_OF_SEQ_FLOW)
            }

            if scanner.peek().type == .flowEntry {
                scanner.pop()
            } else if scanner.peek().type != .flowSeqEnd {
                throw YAMLError.parser(mark: scanner.peek().mark, message: ErrorMsg.END_OF_SEQ_FLOW)
            }
        }

        collectionStack.popCollectionType(.flowSeq)
    }

    private func handleMap(_ eventHandler: EventHandler) throws {
        switch scanner.peek().type {
        case .blockMapStart:
            try handleBlockMap(eventHandler)
        case .flowMapStart:
            try handleFlowMap(eventHandler)
        case .key:
            try handleCompactMap(eventHandler)
        case .value:
            try handleCompactMapWithNoKey(eventHandler)
        default:
            break
        }
    }

    private func handleBlockMap(_ eventHandler: EventHandler) throws {
        scanner.pop()
        collectionStack.pushCollectionType(.blockMap)

        while true {
            guard !scanner.isEmpty else {
                throw YAMLError.parser(mark: scanner.mark(), message: ErrorMsg.END_OF_MAP)
            }

            let token = scanner.peek()
            guard token.type == .key || token.type == .value || token.type == .blockEnd else {
                throw YAMLError.parser(mark: token.mark, message: ErrorMsg.END_OF_MAP)
            }

            if token.type == .blockEnd {
                scanner.pop()
                break
            }

            // Key
            if token.type == .key {
                scanner.pop()
                try handleNode(eventHandler)
            } else {
                eventHandler.onNull(token.mark, anchor: nullAnchor)
            }

            // Value
            if !scanner.isEmpty && scanner.peek().type == .value {
                scanner.pop()
                try handleNode(eventHandler)
            } else {
                eventHandler.onNull(token.mark, anchor: nullAnchor)
            }
        }

        collectionStack.popCollectionType(.blockMap)
    }

    private func handleFlowMap(_ eventHandler: EventHandler) throws {
        scanner.pop()
        collectionStack.pushCollectionType(.flowMap)

        while true {
            guard !scanner.isEmpty else {
                throw YAMLError.parser(mark: scanner.mark(), message: ErrorMsg.END_OF_MAP_FLOW)
            }

            let mark = scanner.peek().mark

            if scanner.peek().type == .flowMapEnd {
                scanner.pop()
                break
            }

            // Key
            if scanner.peek().type == .key {
                scanner.pop()
                try handleNode(eventHandler)
            } else {
                eventHandler.onNull(mark, anchor: nullAnchor)
            }

            // Value
            if !scanner.isEmpty && scanner.peek().type == .value {
                scanner.pop()
                try handleNode(eventHandler)
            } else {
                eventHandler.onNull(mark, anchor: nullAnchor)
            }

            guard !scanner.isEmpty else {
                throw YAMLError.parser(mark: scanner.mark(), message: ErrorMsg.END_OF_MAP_FLOW)
            }

            if scanner.peek().type == .flowEntry {
                scanner.pop()
            } else if scanner.peek().type != .flowMapEnd {
                throw YAMLError.parser(mark: scanner.peek().mark, message: ErrorMsg.END_OF_MAP_FLOW)
            }
        }

        collectionStack.popCollectionType(.flowMap)
    }

    private func handleCompactMap(_ eventHandler: EventHandler) throws {
        collectionStack.pushCollectionType(.compactMap)

        let mark = scanner.peek().mark
        scanner.pop()
        try handleNode(eventHandler)

        if !scanner.isEmpty && scanner.peek().type == .value {
            scanner.pop()
            try handleNode(eventHandler)
        } else {
            eventHandler.onNull(mark, anchor: nullAnchor)
        }

        collectionStack.popCollectionType(.compactMap)
    }

    private func handleCompactMapWithNoKey(_ eventHandler: EventHandler) throws {
        collectionStack.pushCollectionType(.compactMap)

        eventHandler.onNull(scanner.peek().mark, anchor: nullAnchor)
        scanner.pop()
        try handleNode(eventHandler)

        collectionStack.popCollectionType(.compactMap)
    }

    private func parseProperties(_ tag: inout String, _ anchor: inout AnchorID, _ anchorName: inout String) {
        tag = ""
        anchorName = ""
        anchor = nullAnchor

        while !scanner.isEmpty {
            switch scanner.peek().type {
            case .tag:
                parseTag(&tag)
            case .anchor:
                parseAnchor(&anchor, &anchorName)
            default:
                return
            }
        }
    }

    private func parseTag(_ tag: inout String) {
        let token = scanner.peek()
        let tagInfo = Tag(token)
        tag = tagInfo.translate(directives)
        scanner.pop()
    }

    private func parseAnchor(_ anchor: inout AnchorID, _ anchorName: inout String) {
        let token = scanner.peek()
        anchorName = token.value
        anchor = registerAnchor(token.value)
        scanner.pop()
    }

    private func registerAnchor(_ name: String) -> AnchorID {
        guard !name.isEmpty else { return nullAnchor }
        curAnchor += 1
        anchors[name] = curAnchor
        return curAnchor
    }

    private func lookupAnchor(mark: Mark, name: String) throws -> AnchorID {
        guard let anchor = anchors[name] else {
            throw YAMLError.parser(mark: mark, message: "\(ErrorMsg.UNKNOWN_ANCHOR)\(name)")
        }
        return anchor
    }
}
