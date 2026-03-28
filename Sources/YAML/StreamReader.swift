//
//  StreamReader.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

struct StreamReader {
    private let stream: Stream
    private let offset: Int

    init(_ stream: Stream, offset: Int = 0) {
        self.stream = stream
        self.offset = offset
    }

    var hasMore: Bool {
        stream.readAheadTo(offset)
    }

    subscript(index: Int) -> Character {
        Character(UnicodeScalar(stream.charAt(offset + index)))
    }

    func advance(by n: Int) -> StreamReader {
        StreamReader(stream, offset: offset + n)
    }
}
