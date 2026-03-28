//
//  Tag.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

struct Tag {
    enum TagType: Int {
        case verbatim = 0
        case primaryHandle
        case secondaryHandle
        case namedHandle
        case nonSpecific
    }

    let type: TagType
    let handle: String
    let value: String

    init(_ token: Token) {
        self.type = TagType(rawValue: token.data) ?? .nonSpecific
        self.handle = token.params.first ?? ""
        self.value = token.value
    }

    func translate(_ directives: Directives) -> String {
        switch type {
        case .verbatim:
            return value
        case .primaryHandle:
            return "!" + value
        case .secondaryHandle:
            return directives.translateTagHandle("!!") + value
        case .namedHandle:
            return directives.translateTagHandle("!" + value + "!") + handle
        case .nonSpecific:
            return "!"
        }
    }
}
