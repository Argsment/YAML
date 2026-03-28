//
//  EmitterState.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

enum FmtScope { case local, global }
enum GroupType { case noType, seq, map }
enum FlowType { case noType, flow, block }

final class EmitterState {
    private(set) var isGood = true
    private(set) var lastError = ""

    private var charset = Setting<EmitterManip>(.emitNonAscii)
    private var strFmt = Setting<EmitterManip>(.auto_)
    private var boolFmt = Setting<EmitterManip>(.trueFalseBool)
    private var boolLengthFmt = Setting<EmitterManip>(.longBool)
    private var boolCaseFmt = Setting<EmitterManip>(.lowerCase)
    private var nullFmt = Setting<EmitterManip>(.tildeNull)
    private var intFmt = Setting<EmitterManip>(.dec)
    private var indent = Setting<Int>(2)
    private var preCommentIndent = Setting<Int>(2)
    private var postCommentIndent = Setting<Int>(1)
    private var seqFmt = Setting<EmitterManip>(.block)
    private var mapFmt = Setting<EmitterManip>(.block)
    private var mapKeyFmt = Setting<EmitterManip>(.auto_)
    private var floatPrecision = Setting<Int>(9) // Float.significandBitCount related
    private var doublePrecision = Setting<Int>(17) // Double.significandBitCount related
    private var showTrailingZeroSetting = Setting<Bool>(false)

    private var modifiedSettings = SettingChanges()
    private var globalModifiedSettings = SettingChanges()

    private var groups: [Group] = []
    private(set) var curIndent: Int = 0
    private(set) var hasAnchor = false
    private(set) var hasAlias = false
    private(set) var hasTag = false
    private(set) var hasNonContent = false
    private var docCount: Int = 0

    var hasBegunNode: Bool { hasAnchor || hasTag || hasNonContent }
    var hasBegunContent: Bool { hasAnchor || hasTag }

    func setError(_ error: String) {
        isGood = false
        lastError = error
    }

    // Node handling
    func setAnchor() { hasAnchor = true }
    func setAlias() { hasAlias = true }
    func setTag() { hasTag = true }
    func setNonContent() { hasNonContent = true }

    func setLongKey() {
        guard !groups.isEmpty else { return }
        groups[groups.count - 1].longKey = true
    }

    func forceFlow() {
        guard !groups.isEmpty else { return }
        groups[groups.count - 1].flowType = .flow
    }

    func startedDoc() {
        hasAnchor = false; hasTag = false; hasNonContent = false
    }

    func startedScalar() {
        startedNode()
        clearModifiedSettings()
    }

    func startedGroup(_ type: GroupType) {
        startedNode()
        let lastGroupIndent = groups.last?.indent ?? 0
        curIndent += lastGroupIndent

        let group = Group(type)
        group.modifiedSettings = modifiedSettings
        modifiedSettings = SettingChanges()

        group.flowType = (getFlowType(type) == .block) ? .block : .flow
        group.indent = getIndent()
        groups.append(group)
    }

    func endedGroup(_ type: GroupType) {
        guard !groups.isEmpty else {
            setError(type == .seq ? ErrorMsg.UNEXPECTED_END_SEQ : ErrorMsg.UNEXPECTED_END_MAP)
            return
        }

        if hasTag { setError(ErrorMsg.INVALID_TAG) }
        if hasAnchor { setError(ErrorMsg.INVALID_ANCHOR) }

        let finished = groups.removeLast()
        guard finished.type == type else {
            setError(ErrorMsg.UNMATCHED_GROUP_TAG)
            return
        }

        let lastIndent = groups.last?.indent ?? 0
        curIndent -= lastIndent

        globalModifiedSettings.restore()
        clearModifiedSettings()
        hasAnchor = false; hasTag = false; hasNonContent = false
    }

    private func startedNode() {
        if groups.isEmpty {
            docCount += 1
        } else {
            groups[groups.count - 1].childCount += 1
            if groups[groups.count - 1].childCount % 2 == 0 {
                groups[groups.count - 1].longKey = false
            }
        }
        hasAnchor = false; hasAlias = false; hasTag = false; hasNonContent = false
    }

    // Group queries
    func nextGroupType(_ type: GroupType) -> EmitterNodeType {
        if type == .seq {
            return getFlowType(type) == .block ? .blockSeq : .flowSeq
        }
        return getFlowType(type) == .block ? .blockMap : .flowMap
    }

    func curGroupNodeType() -> EmitterNodeType {
        guard let group = groups.last else { return .noType }
        return group.nodeType
    }

    var curGroupType: GroupType { groups.last?.type ?? .noType }
    var curGroupFlowType: FlowType { groups.last?.flowType ?? .noType }
    var curGroupIndent: Int { groups.last?.indent ?? 0 }
    var curGroupChildCount: Int { groups.isEmpty ? docCount : groups.last!.childCount }
    var curGroupLongKey: Bool { groups.last?.longKey ?? false }

    var lastIndent: Int {
        guard groups.count > 1 else { return 0 }
        return curIndent - groups[groups.count - 2].indent
    }

    // Formatters
    func setLocalValue(_ value: EmitterManip) {
        setOutputCharset(value, .local)
        setStringFormat(value, .local)
        setBoolFormat(value, .local)
        setBoolCaseFormat(value, .local)
        setBoolLengthFormat(value, .local)
        setNullFormat(value, .local)
        setIntFormat(value, .local)
        setFlowType(.seq, value, .local)
        setFlowType(.map, value, .local)
        setMapKeyFormat(value, .local)
    }

    @discardableResult func setOutputCharset(_ v: EmitterManip, _ scope: FmtScope) -> Bool {
        switch v { case .emitNonAscii, .escapeNonAscii, .escapeAsJson: _set(charset, v, scope); return true; default: return false }
    }
    var getOutputCharset: EmitterManip { charset.get() }

    @discardableResult func setStringFormat(_ v: EmitterManip, _ scope: FmtScope) -> Bool {
        switch v { case .auto_, .singleQuoted, .doubleQuoted, .literal: _set(strFmt, v, scope); return true; default: return false }
    }
    var getStringFormat: EmitterManip { strFmt.get() }

    @discardableResult func setBoolFormat(_ v: EmitterManip, _ scope: FmtScope) -> Bool {
        switch v { case .onOffBool, .trueFalseBool, .yesNoBool: _set(boolFmt, v, scope); return true; default: return false }
    }
    var getBoolFormat: EmitterManip { boolFmt.get() }

    @discardableResult func setBoolLengthFormat(_ v: EmitterManip, _ scope: FmtScope) -> Bool {
        switch v { case .longBool, .shortBool: _set(boolLengthFmt, v, scope); return true; default: return false }
    }
    var getBoolLengthFormat: EmitterManip { boolLengthFmt.get() }

    @discardableResult func setBoolCaseFormat(_ v: EmitterManip, _ scope: FmtScope) -> Bool {
        switch v { case .upperCase, .lowerCase, .camelCase: _set(boolCaseFmt, v, scope); return true; default: return false }
    }
    var getBoolCaseFormat: EmitterManip { boolCaseFmt.get() }

    @discardableResult func setNullFormat(_ v: EmitterManip, _ scope: FmtScope) -> Bool {
        switch v { case .lowerNull, .upperNull, .camelNull, .tildeNull: _set(nullFmt, v, scope); return true; default: return false }
    }
    var getNullFormat: EmitterManip { nullFmt.get() }

    @discardableResult func setIntFormat(_ v: EmitterManip, _ scope: FmtScope) -> Bool {
        switch v { case .dec, .hex, .oct: _set(intFmt, v, scope); return true; default: return false }
    }
    var getIntFormat: EmitterManip { intFmt.get() }

    @discardableResult func setIndent(_ v: Int, _ scope: FmtScope) -> Bool {
        guard v > 1 else { return false }; _set(indent, v, scope); return true
    }
    func getIndent() -> Int { indent.get() }

    @discardableResult func setPreCommentIndent(_ v: Int, _ scope: FmtScope) -> Bool {
        guard v > 0 else { return false }; _set(preCommentIndent, v, scope); return true
    }
    func getPreCommentIndent() -> Int { preCommentIndent.get() }

    @discardableResult func setPostCommentIndent(_ v: Int, _ scope: FmtScope) -> Bool {
        guard v > 0 else { return false }; _set(postCommentIndent, v, scope); return true
    }
    func getPostCommentIndent() -> Int { postCommentIndent.get() }

    @discardableResult func setFlowType(_ groupType: GroupType, _ v: EmitterManip, _ scope: FmtScope) -> Bool {
        switch v { case .block, .flow: _set(groupType == .seq ? seqFmt : mapFmt, v, scope); return true; default: return false }
    }

    func getFlowType(_ groupType: GroupType) -> EmitterManip {
        if curGroupFlowType == .flow { return .flow }
        return groupType == .seq ? seqFmt.get() : mapFmt.get()
    }

    @discardableResult func setMapKeyFormat(_ v: EmitterManip, _ scope: FmtScope) -> Bool {
        switch v { case .auto_, .longKey: _set(mapKeyFmt, v, scope); return true; default: return false }
    }
    var getMapKeyFormat: EmitterManip { mapKeyFmt.get() }

    @discardableResult func setFloatPrecision(_ v: Int, _ scope: FmtScope) -> Bool { _set(floatPrecision, v, scope); return true }
    func getFloatPrecision() -> Int { floatPrecision.get() }

    @discardableResult func setDoublePrecision(_ v: Int, _ scope: FmtScope) -> Bool { _set(doublePrecision, v, scope); return true }
    func getDoublePrecision() -> Int { doublePrecision.get() }

    @discardableResult func setShowTrailingZero(_ v: Bool, _ scope: FmtScope) -> Bool { _set(showTrailingZeroSetting, v, scope); return true }
    var getShowTrailingZero: Bool { showTrailingZeroSetting.get() }

    func clearModifiedSettings() { modifiedSettings.clear() }
    func restoreGlobalModifiedSettings() { globalModifiedSettings.restore() }

    private func _set<T>(_ setting: Setting<T>, _ value: T, _ scope: FmtScope) {
        switch scope {
        case .local:
            modifiedSettings.push(setting.set(value))
        case .global:
            setting.set(value)
            globalModifiedSettings.push(setting.set(value))
        }
    }

    // Group class
    final class Group {
        var type: GroupType
        var flowType: FlowType = .noType
        var indent: Int = 0
        var childCount: Int = 0
        var longKey: Bool = false
        var modifiedSettings = SettingChanges()

        init(_ type: GroupType) { self.type = type }

        var nodeType: EmitterNodeType {
            if type == .seq {
                return flowType == .flow ? .flowSeq : .blockSeq
            }
            return flowType == .flow ? .flowMap : .blockMap
        }
    }
}
