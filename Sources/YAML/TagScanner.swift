//
//  ScanTag.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

func scanVerbatimTag(_ input: Stream) throws -> String {
    var tag = ""
    // eat '<'
    input.eat(1)

    while input.isValid {
        let ch = input.peek()
        if ch == UInt8(ascii: ">") {
            input.eat(1)
            return tag
        }
        tag.append(Character(UnicodeScalar(input.get())))
    }

    throw YAMLError.parser(mark: input.mark, message: ErrorMsg.END_OF_VERBATIM_TAG)
}

func scanTagHandle(_ input: Stream, canBeHandle: inout Bool) -> String {
    var tag = ""
    canBeHandle = true

    while input.isValid {
        let ch = input.peek()
        if ch == UInt8(ascii: "!") {
            if !tag.isEmpty {
                // We have something like "foo!" - that's a handle prefix
                tag.append("!")
                input.eat(1)
                return tag
            }
        }

        if Pattern.blankOrBreak().matches(StreamReader(input)) || ch == UInt8(ascii: ",") || ch == UInt8(ascii: "[") || ch == UInt8(ascii: "]") || ch == UInt8(ascii: "{") || ch == UInt8(ascii: "}") {
            break
        }

        if !Pattern.wordChar().matches(StreamReader(input)) && ch != UInt8(ascii: "!") {
            canBeHandle = false
        }

        tag.append(Character(UnicodeScalar(input.get())))
    }

    return tag
}

func scanTagSuffix(_ input: Stream) -> String {
    var tag = ""
    while input.isValid {
        let ch = input.peek()
        if Pattern.blankOrBreak().matches(StreamReader(input)) || ch == UInt8(ascii: ",") || ch == UInt8(ascii: "[") || ch == UInt8(ascii: "]") || ch == UInt8(ascii: "{") || ch == UInt8(ascii: "}") {
            break
        }
        tag.append(Character(UnicodeScalar(input.get())))
    }
    return tag
}
