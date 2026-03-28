//
//  CollectionStack.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

enum CollectionType {
    case noCollection
    case blockMap
    case blockSeq
    case flowMap
    case flowSeq
    case compactMap
}

final class CollectionStack {
    private var stack: [CollectionType] = []

    func pushCollectionType(_ type: CollectionType) {
        stack.append(type)
    }

    func popCollectionType(_ type: CollectionType) {
        guard let last = stack.last, last == type else { return }
        stack.removeLast()
    }

    var curCollectionType: CollectionType {
        stack.last ?? .noCollection
    }
}
