//
//  EventHandler.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public protocol EventHandler: AnyObject {
    func onDocumentStart(_ mark: Mark)
    func onDocumentEnd()
    func onNull(_ mark: Mark, anchor: AnchorID)
    func onAlias(_ mark: Mark, anchor: AnchorID)
    func onScalar(_ mark: Mark, tag: String, anchor: AnchorID, value: String)
    func onSequenceStart(_ mark: Mark, tag: String, anchor: AnchorID, style: EmitterStyle)
    func onSequenceEnd()
    func onMapStart(_ mark: Mark, tag: String, anchor: AnchorID, style: EmitterStyle)
    func onMapEnd()
    func onAnchor(_ mark: Mark, anchorName: String)
}

// Default implementation for onAnchor
public extension EventHandler {
    func onAnchor(_ mark: Mark, anchorName: String) {}
}
