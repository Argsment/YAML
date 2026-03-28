//
//  Mark.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public struct Mark: Sendable, Equatable {
    public var pos: Int
    public var line: Int
    public var column: Int

    public init(pos: Int = 0, line: Int = 0, column: Int = 0) {
        self.pos = pos
        self.line = line
        self.column = column
    }

    public static let null = Mark(pos: -1, line: -1, column: -1)

    public var isNull: Bool {
        pos == -1 && line == -1 && column == -1
    }
}
