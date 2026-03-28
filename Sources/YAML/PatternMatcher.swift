//
//  PatternMatcher.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

enum PatternOp {
    case empty
    case match       // single char match
    case range       // char range [a-z]
    case or_         // either of two patterns
    case and_        // both patterns must match at same position
    case not_        // negation
    case seq         // sequence of patterns
    case seqStr      // string sequence (optimization)
}

struct PatternMatcher {
    var op: PatternOp
    var a: Character
    var z: Character
    var params: [PatternMatcher]

    init(_ op: PatternOp = .empty) {
        self.op = op
        self.a = "\0"
        self.z = "\0"
        self.params = []
    }

    init(char ch: Character) {
        self.op = .match
        self.a = ch
        self.z = "\0"
        self.params = []
    }

    init(range a: Character, _ z: Character) {
        self.op = .range
        self.a = a
        self.z = z
        self.params = []
    }

    init(string str: String, op: PatternOp = .seqStr) {
        self.op = op
        self.a = "\0"
        self.z = "\0"
        self.params = str.map { PatternMatcher(char: $0) }
    }

    // Match against a StringReader, returning match length or -1
    func match(_ source: StringReader) -> Int {
        switch op {
        case .empty:
            return -1
        case .match:
            if !source.hasMore { return -1 }
            return source[0] == a ? 1 : -1
        case .range:
            if !source.hasMore { return -1 }
            let ch = source[0]
            return (ch >= a && ch <= z) ? 1 : -1
        case .or_:
            for p in params {
                let n = p.match(source)
                if n >= 0 { return n }
            }
            return -1
        case .and_:
            var longest = -1
            for p in params {
                let n = p.match(source)
                if n == -1 { return -1 }
                longest = max(longest, n)
            }
            return longest
        case .not_:
            guard !params.isEmpty else { return -1 }
            if !source.hasMore { return -1 }
            return params[0].match(source) >= 0 ? -1 : 1
        case .seq:
            var offset = 0
            for p in params {
                let n = p.match(source.advance(by: offset))
                if n == -1 { return -1 }
                offset += n
            }
            return offset
        case .seqStr:
            var offset = 0
            for p in params {
                let n = p.match(source.advance(by: offset))
                if n == -1 { return -1 }
                offset += n
            }
            return offset
        }
    }

    // Match against a Stream via StreamReader
    func match(_ source: StreamReader) -> Int {
        switch op {
        case .empty:
            return -1
        case .match:
            if !source.hasMore { return -1 }
            return source[0] == a ? 1 : -1
        case .range:
            if !source.hasMore { return -1 }
            let ch = source[0]
            return (ch >= a && ch <= z) ? 1 : -1
        case .or_:
            for p in params {
                let n = p.match(source)
                if n >= 0 { return n }
            }
            return -1
        case .and_:
            var longest = -1
            for p in params {
                let n = p.match(source)
                if n == -1 { return -1 }
                longest = max(longest, n)
            }
            return longest
        case .not_:
            guard !params.isEmpty else { return -1 }
            if !source.hasMore { return -1 }
            return params[0].match(source) >= 0 ? -1 : 1
        case .seq:
            var offset = 0
            for p in params {
                let n = p.match(source.advance(by: offset))
                if n == -1 { return -1 }
                offset += n
            }
            return offset
        case .seqStr:
            var offset = 0
            for p in params {
                let n = p.match(source.advance(by: offset))
                if n == -1 { return -1 }
                offset += n
            }
            return offset
        }
    }

    // Convenience: does this match at all?
    func matches(_ source: StreamReader) -> Bool {
        match(source) >= 0
    }

    func matches(_ source: StringReader) -> Bool {
        match(source) >= 0
    }

    // Convenience: match a single character
    func matches(_ ch: Character) -> Bool {
        let src = StringReader(String(ch))
        return match(src) >= 0
    }
}

// Operators for combining PatternMatcher patterns
func | (lhs: PatternMatcher, rhs: PatternMatcher) -> PatternMatcher {
    var r = PatternMatcher(.or_)
    r.params = [lhs, rhs]
    return r
}

func & (lhs: PatternMatcher, rhs: PatternMatcher) -> PatternMatcher {
    var r = PatternMatcher(.and_)
    r.params = [lhs, rhs]
    return r
}

prefix func ! (ex: PatternMatcher) -> PatternMatcher {
    var r = PatternMatcher(.not_)
    r.params = [ex]
    return r
}

func + (lhs: PatternMatcher, rhs: PatternMatcher) -> PatternMatcher {
    var r = PatternMatcher(.seq)
    r.params = [lhs, rhs]
    return r
}
