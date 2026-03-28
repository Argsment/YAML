//
//  Binary.swift
//  YAML
//
//  Created by Argsment Limited on 3/28/26.
//

private let encodingTable: [UInt8] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)

private let decodingTable: [UInt8] = {
    var table = [UInt8](repeating: 255, count: 256)
    for (i, ch) in encodingTable.enumerated() {
        table[Int(ch)] = UInt8(i)
    }
    table[Int(UInt8(ascii: "="))] = 0
    return table
}()

public func encodeBase64(_ data: [UInt8]) -> String {
    let pad: UInt8 = UInt8(ascii: "=")
    var result = [UInt8]()
    result.reserveCapacity(4 * data.count / 3 + 4)

    let chunks = data.count / 3
    let remainder = data.count % 3
    var offset = 0

    for _ in 0..<chunks {
        result.append(encodingTable[Int(data[offset] >> 2)])
        result.append(encodingTable[Int(((data[offset] & 0x3) << 4) | (data[offset+1] >> 4))])
        result.append(encodingTable[Int(((data[offset+1] & 0xf) << 2) | (data[offset+2] >> 6))])
        result.append(encodingTable[Int(data[offset+2] & 0x3f)])
        offset += 3
    }

    switch remainder {
    case 1:
        result.append(encodingTable[Int(data[offset] >> 2)])
        result.append(encodingTable[Int((data[offset] & 0x3) << 4)])
        result.append(pad)
        result.append(pad)
    case 2:
        result.append(encodingTable[Int(data[offset] >> 2)])
        result.append(encodingTable[Int(((data[offset] & 0x3) << 4) | (data[offset+1] >> 4))])
        result.append(encodingTable[Int((data[offset+1] & 0xf) << 2)])
        result.append(pad)
    default:
        break
    }

    return String(bytes: result, encoding: .ascii)!
}

public func decodeBase64(_ input: String) -> [UInt8]? {
    if input.isEmpty { return [] }

    var result = [UInt8]()
    result.reserveCapacity(3 * input.count / 4 + 1)

    var value: UInt32 = 0
    var cnt = 0
    let bytes = Array(input.utf8)

    for i in 0..<bytes.count {
        let byte = bytes[i]
        // skip whitespace
        if byte == 0x20 || byte == 0x0A || byte == 0x0D || byte == 0x09 { continue }

        let d = decodingTable[Int(byte)]
        if d == 255 { return nil }

        value = (value << 6) | UInt32(d)
        if cnt == 3 {
            result.append(UInt8(value >> 16))
            if i > 0 && bytes[i - 1] != UInt8(ascii: "=") {
                result.append(UInt8((value >> 8) & 0xFF))
            }
            if byte != UInt8(ascii: "=") {
                result.append(UInt8(value & 0xFF))
            }
            cnt = 0
            value = 0
        } else {
            cnt += 1
        }
    }

    if cnt != 0 { return nil }

    return result
}

public struct Binary: Sendable, Equatable {
    private var storage: [UInt8]

    public init() {
        self.storage = []
    }

    public init(_ data: [UInt8]) {
        self.storage = data
    }

    public var size: Int { storage.count }
    public var data: [UInt8] { storage }

    public static func == (lhs: Binary, rhs: Binary) -> Bool {
        lhs.storage == rhs.storage
    }
}
