//
//  EmitterDef.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public enum EmitterNodeType: Sendable {
    case noType
    case property
    case scalar
    case flowSeq
    case blockSeq
    case flowMap
    case blockMap
}
