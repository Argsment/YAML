//
//  EmitFromEvents.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

final class EmitFromEvents: EventHandler {
    private let emitter: Emitter

    enum State { case waitingForSequenceEntry, waitingForKey, waitingForValue }
    private var stateStack: [State] = []

    init(_ emitter: Emitter) {
        self.emitter = emitter
    }

    func onDocumentStart(_ mark: Mark) {}
    func onDocumentEnd() {}

    func onNull(_ mark: Mark, anchor: AnchorID) {
        beginNode()
        emitProps("", anchor)
        emitter.emitNull()
    }

    func onAlias(_ mark: Mark, anchor: AnchorID) {
        beginNode()
        emitter.emit(Alias("\(anchor)"))
    }

    func onScalar(_ mark: Mark, tag: String, anchor: AnchorID, value: String) {
        beginNode()
        emitProps(tag, anchor)
        emitter.emit(value)
    }

    func onSequenceStart(_ mark: Mark, tag: String, anchor: AnchorID, style: EmitterStyle) {
        beginNode()
        emitProps(tag, anchor)
        switch style {
        case .block: emitter.emit(.block)
        case .flow: emitter.emit(.flow)
        default: break
        }
        emitter.restoreGlobalModifiedSettings()
        emitter.emit(.beginSeq)
        stateStack.append(.waitingForSequenceEntry)
    }

    func onSequenceEnd() {
        emitter.emit(.endSeq)
        stateStack.removeLast()
    }

    func onMapStart(_ mark: Mark, tag: String, anchor: AnchorID, style: EmitterStyle) {
        beginNode()
        emitProps(tag, anchor)
        switch style {
        case .block: emitter.emit(.block)
        case .flow: emitter.emit(.flow)
        default: break
        }
        emitter.restoreGlobalModifiedSettings()
        emitter.emit(.beginMap)
        stateStack.append(.waitingForKey)
    }

    func onMapEnd() {
        emitter.emit(.endMap)
        stateStack.removeLast()
    }

    private func beginNode() {
        guard !stateStack.isEmpty else { return }
        switch stateStack[stateStack.count - 1] {
        case .waitingForKey:
            emitter.emit(.key)
            stateStack[stateStack.count - 1] = .waitingForValue
        case .waitingForValue:
            emitter.emit(.value)
            stateStack[stateStack.count - 1] = .waitingForKey
        default: break
        }
    }

    private func emitProps(_ tag: String, _ anchor: AnchorID) {
        if !tag.isEmpty && tag != "?" && tag != "!" {
            if tag.hasPrefix("!") {
                emitter.emit(localTag(String(tag.dropFirst())))
            } else {
                emitter.emit(verbatimTag(tag))
            }
        }
        if anchor != nullAnchor {
            emitter.emit(AnchorManip("\(anchor)"))
        }
    }
}
