import Foundation
import SwiftUI
import CryptoKit
import TrueAuthKit

struct Profile: Identifiable, Codable {
    var id = UUID()
    var name: String
    var secret: String

    var isValid: Bool {
        TOTP.generate(secret: secret) != nil
    }
}

@MainActor
class ProfileStore: ObservableObject {
    @Published var profiles: [Profile] = []

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TrueAuth", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("profiles.enc")
    }

    private let key: SymmetricKey

    init() {
        key = KeychainHelper.getOrCreateKey()
        load()
        migrateIfNeeded()
    }

    // MARK: - Encrypted persistence

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        guard let box = try? ChaChaPoly.SealedBox(combined: data),
              let decrypted = try? ChaChaPoly.open(box, using: key),
              let decoded = try? JSONDecoder().decode([Profile].self, from: decrypted) else { return }
        profiles = decoded
    }

    func save() {
        guard let json = try? JSONEncoder().encode(profiles),
              let sealed = try? ChaChaPoly.seal(json, using: key) else { return }
        try? sealed.combined.write(to: fileURL, options: .atomic)
    }

    /// Migrate from old plaintext profiles.json
    private func migrateIfNeeded() {
        guard profiles.isEmpty else { return }
        let oldURL = fileURL.deletingLastPathComponent().appendingPathComponent("profiles.json")
        guard let data = try? Data(contentsOf: oldURL),
              let decoded = try? JSONDecoder().decode([Profile].self, from: data) else { return }
        profiles = decoded
        save()
        try? FileManager.default.removeItem(at: oldURL)
    }

    func add(name: String, secret: String) {
        profiles.append(Profile(name: name, secret: secret))
        save()
    }

    func delete(_ profile: Profile) {
        profiles.removeAll { $0.id == profile.id }
        save()
    }

    func update(_ profile: Profile) {
        if let i = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[i] = profile
            save()
        }
    }

    /// Import from secrets.txt format: NAME=SECRET
    func importFromFile(_ url: URL) -> Int {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return 0 }
        var count = 0
        for line in content.components(separatedBy: .newlines) {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let name = parts[0].replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespaces)
            let secret = String(parts[1]).trimmingCharacters(in: .whitespaces)
            add(name: name, secret: secret)
            count += 1
        }
        return count
    }

    /// Import from QR code image
    func importFromQR(_ url: URL) -> Bool {
        guard let result = QRCodeParser.readFromImage(url) else { return false }
        add(name: result.name, secret: result.secret)
        return true
    }

    // MARK: - Export

    /// Export as plain secrets.txt format
    func exportPlainText() -> String {
        profiles.map { "\($0.name.replacingOccurrences(of: " ", with: "_"))=\($0.secret)" }
            .joined(separator: "\n")
    }

    /// Export as password-encrypted JSON
    func exportEncrypted(password: String) -> Data? {
        guard let json = try? JSONEncoder().encode(profiles) else { return nil }
        let passKey = deriveKey(from: password)
        guard let sealed = try? ChaChaPoly.seal(json, using: passKey) else { return nil }
        return sealed.combined
    }

    /// Import from password-encrypted JSON
    func importEncrypted(data: Data, password: String) -> Bool {
        let passKey = deriveKey(from: password)
        guard let box = try? ChaChaPoly.SealedBox(combined: data),
              let decrypted = try? ChaChaPoly.open(box, using: passKey),
              let decoded = try? JSONDecoder().decode([Profile].self, from: decrypted) else { return false }
        for profile in decoded {
            if !profiles.contains(where: { $0.secret == profile.secret }) {
                profiles.append(profile)
            }
        }
        save()
        return true
    }

    private func deriveKey(from password: String) -> SymmetricKey {
        let passData = Data(password.utf8)
        let hash = SHA256.hash(data: passData)
        return SymmetricKey(data: hash)
    }
}
