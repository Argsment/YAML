//
//  DepthGuard.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

final class DepthCounter {
    var value: Int = 0
}

func withDepthGuard(counter: DepthCounter, mark: Mark, message: String, maxDepth: Int = 500, body: () throws -> Void) throws {
    counter.value += 1
    defer { counter.value -= 1 }
    if counter.value >= maxDepth {
        throw YAMLError.deepRecursion(depth: counter.value, mark: mark, message: message)
    }
    try body()
}
