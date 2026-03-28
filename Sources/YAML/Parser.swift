//
//  Parser.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public final class Parser {
    private var scanner: Scanner?
    private var directives = Directives()

    public init() {}

    public init(_ input: String) {
        load(input)
    }

    public var isValid: Bool {
        scanner != nil && !scanner!.isEmpty
    }

    public func load(_ input: String) {
        scanner = Scanner(input)
        directives = Directives()
    }

    public func handleNextDocument(_ eventHandler: EventHandler) throws -> Bool {
        guard let scanner = scanner else { return false }

        parseDirectives()
        if scanner.isEmpty { return false }

        let oldPos = scanner.peek().mark.pos

        let sdp = SingleDocParser(scanner, directives)
        try sdp.handleDocument(eventHandler)

        if scanner.isEmpty { return true }

        let newPos = scanner.peek().mark.pos
        return newPos != oldPos
    }

    private func parseDirectives() {
        guard let scanner = scanner else { return }
        var readDirective = false

        while !scanner.isEmpty {
            let token = scanner.peek()
            guard token.type == .directive else { break }

            if !readDirective {
                directives = Directives()
            }

            readDirective = true
            handleDirective(token)
            scanner.pop()
        }
    }

    private func handleDirective(_ token: Token) {
        if token.value == "YAML" {
            handleYamlDirective(token)
        } else if token.value == "TAG" {
            handleTagDirective(token)
        }
    }

    private func handleYamlDirective(_ token: Token) {
        // Parse version like "1.2"
        guard token.params.count == 1 else { return }
        let parts = token.params[0].split(separator: ".")
        guard parts.count == 2,
              let major = Int(parts[0]),
              let minor = Int(parts[1]) else { return }
        directives.version = Version(isDefault: false, major: major, minor: minor)
    }

    private func handleTagDirective(_ token: Token) {
        guard token.params.count == 2 else { return }
        directives.tags[token.params[0]] = token.params[1]
    }
}
