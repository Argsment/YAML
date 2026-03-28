//
//  Directives.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

struct Version {
    var isDefault: Bool
    var major: Int
    var minor: Int
}

struct Directives {
    var version: Version = Version(isDefault: true, major: 1, minor: 2)
    var tags: [String: String] = [:]

    func translateTagHandle(_ handle: String) -> String {
        if let prefix = tags[handle] {
            return prefix
        }
        if handle == "!!" {
            return "tag:yaml.org,2002:"
        }
        return handle
    }
}
