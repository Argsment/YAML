//
//  Indentation.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

struct Indentation {
    let width: Int
    init(_ width: Int) { self.width = width }
}

struct IndentTo {
    let column: Int
    init(_ column: Int) { self.column = column }
}
