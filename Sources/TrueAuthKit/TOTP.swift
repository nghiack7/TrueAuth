import Foundation
import CryptoKit

public struct TOTP {
    public static func generate(secret: String, time: Date = Date(), period: Int = 30, digits: Int = 6) -> String? {
        guard let keyData = base32Decode(secret.uppercased().replacingOccurrences(of: " ", with: "")) else {
            return nil
        }

        let counter = UInt64(time.timeIntervalSince1970) / UInt64(period)
        var counterBig = counter.bigEndian
        let counterData = Data(bytes: &counterBig, count: 8)

        let key = SymmetricKey(data: keyData)
        let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
        let hmacBytes = Array(hmac)

        let offset = Int(hmacBytes[hmacBytes.count - 1] & 0x0f)
        let truncated = (UInt32(hmacBytes[offset]) & 0x7f) << 24
            | UInt32(hmacBytes[offset + 1]) << 16
            | UInt32(hmacBytes[offset + 2]) << 8
            | UInt32(hmacBytes[offset + 3])

        let otp = truncated % UInt32(pow(10, Float(digits)))
        return String(format: "%0\(digits)d", otp)
    }

    public static func remainingSeconds(period: Int = 30) -> Int {
        period - Int(Date().timeIntervalSince1970) % period
    }

    // MARK: - Base32
    private static func base32Decode(_ input: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var bits = ""
        for char in input {
            if char == "=" { continue }
            guard let idx = alphabet.firstIndex(of: char) else { return nil }
            let val = alphabet.distance(from: alphabet.startIndex, to: idx)
            bits += String(val, radix: 2).leftPadded(to: 5)
        }
        var bytes = Data()
        var i = bits.startIndex
        while bits.distance(from: i, to: bits.endIndex) >= 8 {
            let end = bits.index(i, offsetBy: 8)
            if let byte = UInt8(bits[i..<end], radix: 2) {
                bytes.append(byte)
            }
            i = end
        }
        return bytes.isEmpty ? nil : bytes
    }
}

extension String {
    public func leftPadded(to length: Int, with char: Character = "0") -> String {
        String(repeating: char, count: max(0, length - count)) + self
    }
}
