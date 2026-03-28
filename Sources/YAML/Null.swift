//
//  Null.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

public struct YAMLNull: Sendable, Equatable {}

public let yamlNull = YAMLNull()

public func isNullString(_ str: String) -> Bool {
    str.isEmpty || str == "~" || str == "null" || str == "Null" || str == "NULL"
}

public func isNullString(_ chars: UnsafeBufferPointer<UInt8>) -> Bool {
    if chars.isEmpty { return true }
    let count = chars.count
    if count == 1 && chars[0] == UInt8(ascii: "~") { return true }
    if count == 4 {
        let n: UInt8 = 0x6E, u: UInt8 = 0x75, l: UInt8 = 0x6C
        let capN: UInt8 = 0x4E, capU: UInt8 = 0x55, capL: UInt8 = 0x4C
        if chars[0] == n && chars[1] == u && chars[2] == l && chars[3] == l { return true }
        if chars[0] == capN && chars[1] == u && chars[2] == l && chars[3] == l { return true }
        if chars[0] == capN && chars[1] == capU && chars[2] == capL && chars[3] == capL { return true }
    }
    return false
}
