import Foundation

enum SpotIDCoder {
    private static let alphabet: [Character] = Array("5kRmHvNpLqT8sYuWdXjZcFbGiOeA9n2BgVrMo3CQfthE0SaKwIPDy61lJU74xz")
    private static let base = UInt64(alphabet.count)
    private static let separator: Character = "-"

    // Encodes [type, id] as two base-N numbers joined by separator
    // e.g. spot(type=1) + id=123 → "k-3mHv"
    static func encodeSpot(_ id: Int64) -> String {
        encode(1) + String(separator) + encode(id)
    }

    static func decodeSpot(_ token: String) -> Int64? {
        let parts = token.split(separator: separator, maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let type = decode(parts[0]), type == 1,
              let id = decode(parts[1]) else { return nil }
        return id
    }

    private static func encode(_ value: Int64) -> String {
        guard value >= 0 else { return "" }
        var num = UInt64(bitPattern: value)
        var chars: [Character] = []
        repeat {
            chars.insert(alphabet[Int(num % base)], at: 0)
            num /= base
        } while num > 0
        return String(chars)
    }

    private static func decode(_ encoded: String) -> Int64? {
        var result: Int64 = 0
        let base = Int64(alphabet.count)
        for char in encoded {
            guard let idx = alphabet.firstIndex(of: char) else { return nil }
            let offset = Int64(idx)
            guard result <= (Int64.max - offset) / base else { return nil }
            result = result * base + offset
        }
        return result
    }
}
