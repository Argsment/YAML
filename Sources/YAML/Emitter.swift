//
//  Emitter.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public final class Emitter {
    private let state = EmitterState()
    private let stream = StringOutput()

    public init() {}

    public var string: String { stream.string }
    public var good: Bool { state.isGood }
    public var lastError: String { state.lastError }

    // Global setters
    @discardableResult public func setOutputCharset(_ v: EmitterManip) -> Bool { state.setOutputCharset(v, .global) }
    @discardableResult public func setStringFormat(_ v: EmitterManip) -> Bool { state.setStringFormat(v, .global) }
    @discardableResult public func setNullFormat(_ v: EmitterManip) -> Bool { state.setNullFormat(v, .global) }
    @discardableResult public func setSeqFormat(_ v: EmitterManip) -> Bool { state.setFlowType(.seq, v, .global) }
    @discardableResult public func setMapFormat(_ v: EmitterManip) -> Bool { state.setFlowType(.map, v, .global) }
    @discardableResult public func setIndent(_ n: Int) -> Bool { state.setIndent(n, .global) }

    public func restoreGlobalModifiedSettings() { state.restoreGlobalModifiedSettings() }

    // Emit manipulators
    @discardableResult
    public func emit(_ manip: EmitterManip) -> Emitter {
        guard good else { return self }
        switch manip {
        case .beginDoc: emitBeginDoc()
        case .endDoc: emitEndDoc()
        case .beginSeq: emitBeginSeq()
        case .endSeq: emitEndSeq()
        case .beginMap: emitBeginMap()
        case .endMap: emitEndMap()
        case .newline: emitNewline()
        case .key, .value: break // deprecated
        case .tagByKind: emitKindTag()
        default: state.setLocalValue(manip)
        }
        return self
    }

    // Emit string
    @discardableResult
    public func emit(_ str: String) -> Emitter {
        guard good else { return self }
        let escapingStyle = getStringEscapingStyle(state.getOutputCharset)
        let strFormat = EmitterUtils.computeStringFormat(str, format: state.getStringFormat, flowType: state.curGroupFlowType, escapeNonAscii: escapingStyle == .nonAscii)

        if strFormat == .literal || str.count > 1024 {
            state.setMapKeyFormat(.longKey, .local)
        }

        prepareNode(.scalar)

        switch strFormat {
        case .plain: stream.write(str)
        case .singleQuoted: EmitterUtils.writeSingleQuotedString(stream, str)
        case .doubleQuoted: EmitterUtils.writeDoubleQuotedString(stream, str, escaping: escapingStyle)
        case .literal: EmitterUtils.writeLiteralString(stream, str, indent: state.curIndent + state.getIndent())
        }

        state.startedScalar()
        return self
    }

    @discardableResult public func emit(_ b: Bool) -> Emitter {
        guard good else { return self }
        prepareNode(.scalar)
        stream.write(computeFullBoolName(b))
        state.startedScalar()
        return self
    }

    @discardableResult public func emit(_ v: Int) -> Emitter {
        guard good else { return self }
        prepareNode(.scalar)
        switch state.getIntFormat {
        case .hex: stream.write("0x" + String(v, radix: 16))
        case .oct: stream.write("0" + String(v, radix: 8))
        default: stream.write(String(v))
        }
        state.startedScalar()
        return self
    }

    @discardableResult public func emit(_ v: Double) -> Emitter {
        guard good else { return self }
        prepareNode(.scalar)
        if v.isNaN { stream.write(".nan") }
        else if v.isInfinite { stream.write(v < 0 ? "-.inf" : ".inf") }
        else { stream.write(fpToString(v, precision: state.getDoublePrecision())) }
        state.startedScalar()
        return self
    }

    @discardableResult public func emitNull() -> Emitter {
        guard good else { return self }
        prepareNode(.scalar)
        stream.write(computeNullName())
        state.startedScalar()
        return self
    }

    @discardableResult public func emit(_ alias: Alias) -> Emitter {
        guard good else { return self }
        prepareNode(.scalar)
        EmitterUtils.writeAlias(stream, alias.content)
        state.startedScalar()
        state.setAlias()
        return self
    }

    @discardableResult public func emit(_ anchor: AnchorManip) -> Emitter {
        guard good else { return self }
        prepareNode(.property)
        EmitterUtils.writeAnchor(stream, anchor.content)
        state.setAnchor()
        return self
    }

    @discardableResult public func emit(_ tag: TagManip) -> Emitter {
        guard good else { return self }
        prepareNode(.property)
        switch tag.type {
        case .verbatim: EmitterUtils.writeTag(stream, tag.content, verbatim: true)
        case .primaryHandle: EmitterUtils.writeTag(stream, tag.content, verbatim: false)
        case .namedHandle: EmitterUtils.writeTagWithPrefix(stream, prefix: tag.prefix, tag: tag.content)
        }
        state.setTag()
        return self
    }

    @discardableResult public func emit(_ comment: Comment) -> Emitter {
        guard good else { return self }
        prepareNode(.noType)
        if stream.col > 0 { stream.writeIndentation(state.getPreCommentIndent()) }
        EmitterUtils.writeComment(stream, comment.content, postCommentIndent: state.getPostCommentIndent())
        state.setNonContent()
        return self
    }

    // Emit a node
    @discardableResult public func emit(_ node: Node) -> Emitter {
        let emitFromEvents = EmitFromEvents(self)
        let events = NodeEvents(node)
        events.emit(emitFromEvents)
        return self
    }

    // Private helpers
    private func getStringEscapingStyle(_ charset: EmitterManip) -> StringEscaping {
        switch charset {
        case .escapeNonAscii: return .nonAscii
        case .escapeAsJson: return .json
        default: return .none
        }
    }

    private func computeFullBoolName(_ b: Bool) -> String {
        let mainFmt = state.getBoolLengthFormat == .shortBool ? EmitterManip.yesNoBool : state.getBoolFormat
        let caseFmt = state.getBoolCaseFormat
        switch mainFmt {
        case .yesNoBool:
            switch caseFmt {
            case .upperCase: return b ? "YES" : "NO"
            case .camelCase: return b ? "Yes" : "No"
            default: return b ? "yes" : "no"
            }
        case .onOffBool:
            switch caseFmt {
            case .upperCase: return b ? "ON" : "OFF"
            case .camelCase: return b ? "On" : "Off"
            default: return b ? "on" : "off"
            }
        default: // trueFalseBool
            switch caseFmt {
            case .upperCase: return b ? "TRUE" : "FALSE"
            case .camelCase: return b ? "True" : "False"
            default: return b ? "true" : "false"
            }
        }
    }

    private func computeNullName() -> String {
        switch state.getNullFormat {
        case .lowerNull: return "null"
        case .upperNull: return "NULL"
        case .camelNull: return "Null"
        default: return "~"
        }
    }

    private func emitKindTag() { emit(localTag("")) }

    private func emitBeginDoc() {
        guard good else { return }
        if stream.col > 0 { stream.write("\n") }
        stream.write("---\n")
        state.startedDoc()
    }

    private func emitEndDoc() {
        guard good else { return }
        if stream.col > 0 { stream.write("\n") }
        stream.write("...\n")
    }

    private func emitBeginSeq() {
        guard good else { return }
        prepareNode(state.nextGroupType(.seq))
        state.startedGroup(.seq)
    }

    private func emitEndSeq() {
        guard good else { return }
        let originalType = state.curGroupFlowType
        if state.curGroupChildCount == 0 { state.forceFlow() }
        if state.curGroupFlowType == .flow {
            if stream.isComment { stream.write("\n") }
            if originalType == .block || state.hasBegunNode { stream.writeIndentTo(state.curIndent) }
            if originalType == .block { stream.write("[") }
            else if state.curGroupChildCount == 0 && !state.hasBegunNode { stream.write("[") }
            stream.write("]")
        }
        state.endedGroup(.seq)
    }

    private func emitBeginMap() {
        guard good else { return }
        prepareNode(state.nextGroupType(.map))
        state.startedGroup(.map)
    }

    private func emitEndMap() {
        guard good else { return }
        let originalType = state.curGroupFlowType
        if state.curGroupChildCount == 0 { state.forceFlow() }
        if state.curGroupFlowType == .flow {
            if stream.isComment { stream.write("\n") }
            stream.writeIndentTo(state.curIndent)
            if originalType == .block { stream.write("{") }
            else if state.curGroupChildCount == 0 && !state.hasBegunNode { stream.write("{") }
            stream.write("}")
        }
        state.endedGroup(.map)
    }

    private func emitNewline() {
        guard good else { return }
        prepareNode(.noType)
        stream.write("\n")
        state.setNonContent()
    }

    private func prepareNode(_ child: EmitterNodeType) {
        switch state.curGroupNodeType() {
        case .noType: prepareTopNode(child)
        case .flowSeq: flowSeqPrepareNode(child)
        case .blockSeq: blockSeqPrepareNode(child)
        case .flowMap: flowMapPrepareNode(child)
        case .blockMap: blockMapPrepareNode(child)
        default: break
        }
    }

    private func prepareTopNode(_ child: EmitterNodeType) {
        guard child != .noType else { return }
        if state.curGroupChildCount > 0 && stream.col > 0 { emitBeginDoc() }
        switch child {
        case .property, .scalar, .flowSeq, .flowMap:
            spaceOrIndentTo(state.hasBegunContent, 0)
        case .blockSeq, .blockMap:
            if state.hasBegunNode { stream.write("\n") }
        default: break
        }
    }

    private func flowSeqPrepareNode(_ child: EmitterNodeType) {
        let lastIndent = state.lastIndent
        if !state.hasBegunNode {
            if stream.isComment { stream.write("\n") }
            stream.writeIndentTo(lastIndent)
            if state.curGroupChildCount == 0 { stream.write("[") }
            else { stream.write(",") }
        }
        switch child {
        case .property, .scalar, .flowSeq, .flowMap:
            spaceOrIndentTo(state.hasBegunContent || state.curGroupChildCount > 0, lastIndent)
        default: break
        }
    }

    private func blockSeqPrepareNode(_ child: EmitterNodeType) {
        let curIndent = state.curIndent
        let nextIndent = curIndent + state.curGroupIndent
        guard child != .noType else { return }
        if !state.hasBegunContent {
            if state.curGroupChildCount > 0 || stream.isComment { stream.write("\n") }
            stream.writeIndentTo(curIndent)
            stream.write("-")
        }
        switch child {
        case .property, .scalar, .flowSeq, .flowMap:
            spaceOrIndentTo(state.hasBegunContent, nextIndent)
        case .blockSeq:
            stream.write("\n")
        case .blockMap:
            if state.hasBegunContent || stream.isComment { stream.write("\n") }
        default: break
        }
    }

    private func flowMapPrepareNode(_ child: EmitterNodeType) {
        if state.curGroupChildCount % 2 == 0 {
            if state.getMapKeyFormat == .longKey { state.setLongKey() }
            if state.curGroupLongKey { flowMapPrepareLongKey(child) }
            else { flowMapPrepareSimpleKey(child) }
        } else {
            if state.curGroupLongKey { flowMapPrepareLongKeyValue(child) }
            else { flowMapPrepareSimpleKeyValue(child) }
        }
    }

    private func flowMapPrepareLongKey(_ child: EmitterNodeType) {
        let lastIndent = state.lastIndent
        if !state.hasBegunNode {
            if stream.isComment { stream.write("\n") }
            stream.writeIndentTo(lastIndent)
            stream.write(state.curGroupChildCount == 0 ? "{ ?" : ", ?")
        }
        if child == .property || child == .scalar || child == .flowSeq || child == .flowMap {
            spaceOrIndentTo(state.hasBegunContent || state.curGroupChildCount > 0, lastIndent)
        }
    }

    private func flowMapPrepareLongKeyValue(_ child: EmitterNodeType) {
        let lastIndent = state.lastIndent
        if !state.hasBegunNode {
            if stream.isComment { stream.write("\n") }
            stream.writeIndentTo(lastIndent)
            stream.write(":")
        }
        if child == .property || child == .scalar || child == .flowSeq || child == .flowMap {
            spaceOrIndentTo(state.hasBegunContent || state.curGroupChildCount > 0, lastIndent)
        }
    }

    private func flowMapPrepareSimpleKey(_ child: EmitterNodeType) {
        let lastIndent = state.lastIndent
        if !state.hasBegunNode {
            if stream.isComment { stream.write("\n") }
            stream.writeIndentTo(lastIndent)
            stream.write(state.curGroupChildCount == 0 ? "{" : ",")
        }
        if child == .property || child == .scalar || child == .flowSeq || child == .flowMap {
            spaceOrIndentTo(state.hasBegunContent || state.curGroupChildCount > 0, lastIndent)
        }
    }

    private func flowMapPrepareSimpleKeyValue(_ child: EmitterNodeType) {
        let lastIndent = state.lastIndent
        if !state.hasBegunNode {
            if stream.isComment { stream.write("\n") }
            stream.writeIndentTo(lastIndent)
            if state.hasAlias { stream.write(" ") }
            stream.write(":")
        }
        if child == .property || child == .scalar || child == .flowSeq || child == .flowMap {
            spaceOrIndentTo(state.hasBegunContent || state.curGroupChildCount > 0, lastIndent)
        }
    }

    private func blockMapPrepareNode(_ child: EmitterNodeType) {
        if state.curGroupChildCount % 2 == 0 {
            if state.getMapKeyFormat == .longKey { state.setLongKey() }
            if child == .blockSeq || child == .blockMap || child == .property { state.setLongKey() }
            if state.curGroupLongKey { blockMapPrepareLongKey(child) }
            else { blockMapPrepareSimpleKey(child) }
        } else {
            if state.curGroupLongKey { blockMapPrepareLongKeyValue(child) }
            else { blockMapPrepareSimpleKeyValue(child) }
        }
    }

    private func blockMapPrepareLongKey(_ child: EmitterNodeType) {
        let curIndent = state.curIndent
        guard child != .noType else { return }
        if !state.hasBegunContent {
            if state.curGroupChildCount > 0 { stream.write("\n") }
            if stream.isComment { stream.write("\n") }
            stream.writeIndentTo(curIndent)
            stream.write("?")
        }
        switch child {
        case .property, .scalar, .flowSeq, .flowMap:
            spaceOrIndentTo(true, curIndent + 1)
        case .blockSeq, .blockMap:
            if state.hasBegunContent { stream.write("\n") }
        default: break
        }
    }

    private func blockMapPrepareLongKeyValue(_ child: EmitterNodeType) {
        let curIndent = state.curIndent
        guard child != .noType else { return }
        if !state.hasBegunContent {
            stream.write("\n")
            stream.writeIndentTo(curIndent)
            stream.write(":")
        }
        switch child {
        case .property, .scalar, .flowSeq, .flowMap:
            spaceOrIndentTo(true, curIndent + 1)
        case .blockSeq, .blockMap:
            if state.hasBegunContent { stream.write("\n") }
            spaceOrIndentTo(true, curIndent + 1)
        default: break
        }
    }

    private func blockMapPrepareSimpleKey(_ child: EmitterNodeType) {
        let curIndent = state.curIndent
        guard child != .noType else { return }
        if !state.hasBegunNode && state.curGroupChildCount > 0 { stream.write("\n") }
        switch child {
        case .property, .scalar, .flowSeq, .flowMap:
            spaceOrIndentTo(state.hasBegunContent, curIndent)
        default: break
        }
    }

    private func blockMapPrepareSimpleKeyValue(_ child: EmitterNodeType) {
        let nextIndent = state.curIndent + state.curGroupIndent
        if !state.hasBegunNode {
            if state.hasAlias { stream.write(" ") }
            stream.write(":")
        }
        switch child {
        case .property, .scalar, .flowSeq, .flowMap:
            spaceOrIndentTo(true, nextIndent)
        case .blockSeq, .blockMap:
            stream.write("\n")
        default: break
        }
    }

    private func spaceOrIndentTo(_ requireSpace: Bool, _ indent: Int) {
        if stream.isComment { stream.write("\n") }
        if stream.col > 0 && requireSpace { stream.write(" ") }
        stream.writeIndentTo(indent)
    }
}
