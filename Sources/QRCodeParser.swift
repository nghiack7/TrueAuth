import Foundation
import CoreImage

struct QRCodeParser {
    struct OTPAuth {
        let name: String
        let secret: String
    }

    /// Parse otpauth://totp/LABEL?secret=SECRET&issuer=ISSUER
    static func parse(_ uri: String) -> OTPAuth? {
        guard let url = URL(string: uri),
              url.scheme == "otpauth",
              url.host == "totp" else { return nil }

        let label = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard let secret = params.first(where: { $0.name == "secret" })?.value else { return nil }

        let issuer = params.first(where: { $0.name == "issuer" })?.value
        let name = issuer.map { "\($0): \(label.replacingOccurrences(of: "\($0):", with: "").trimmingCharacters(in: .whitespaces))" }
            ?? label.removingPercentEncoding
            ?? label

        return OTPAuth(name: name, secret: secret)
    }

    /// Read QR code from image file and extract otpauth:// URI
    static func readFromImage(_ url: URL) -> OTPAuth? {
        guard let ciImage = CIImage(contentsOf: url) else { return nil }
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] ?? []

        for feature in features {
            if let message = feature.messageString, message.hasPrefix("otpauth://") {
                return parse(message)
            }
        }
        return nil
    }
}
