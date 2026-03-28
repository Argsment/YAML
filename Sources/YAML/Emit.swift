//
//  Emit.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public func dump(_ node: Node) -> String {
    let emitter = Emitter()
    emitter.emit(node)
    return emitter.string
}
