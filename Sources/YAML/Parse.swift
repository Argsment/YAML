//
//  Parse.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

import Foundation

public func load(_ input: String) throws -> Node {
    let parser = Parser(input)
    let builder = NodeBuilder()
    guard try parser.handleNextDocument(builder) else { return Node() }
    return builder.rootNode()
}

public func loadAll(_ input: String) throws -> [Node] {
    let parser = Parser(input)
    var docs: [Node] = []
    while true {
        let builder = NodeBuilder()
        guard try parser.handleNextDocument(builder) else { break }
        docs.append(builder.rootNode())
    }
    return docs
}

public func loadFile(_ filename: String) throws -> Node {
    guard let data = FileManager.default.contents(atPath: filename),
          let content = String(data: data, encoding: .utf8) else {
        throw YAMLError.badFile(filename: filename)
    }
    return try load(content)
}

public func loadAllFromFile(_ filename: String) throws -> [Node] {
    guard let data = FileManager.default.contents(atPath: filename),
          let content = String(data: data, encoding: .utf8) else {
        throw YAMLError.badFile(filename: filename)
    }
    return try loadAll(content)
}

public func clone(_ node: Node) -> Node {
    let events = NodeEvents(node)
    let builder = NodeBuilder()
    events.emit(builder)
    return builder.rootNode()
}
