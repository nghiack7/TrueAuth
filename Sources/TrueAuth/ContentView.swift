import SwiftUI
import UniformTypeIdentifiers
import TrueAuthKit

struct ContentView: View {
    @EnvironmentObject var store: ProfileStore
    @State private var showingAdd = false
    @State private var showingImportText = false
    @State private var showingImportQR = false
    @State private var showingExport = false
    @State private var editingProfile: Profile?
    @State private var tick = 0

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("TrueAuth")
                    .font(.title2.bold())
                Spacer()
                TimerRing(remaining: TOTP.remainingSeconds())
                    .frame(width: 32, height: 32)
            }
            .padding()

            Divider()

            if store.profiles.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No profiles yet")
                        .foregroundStyle(.secondary)
                    Button("Add Profile") { showingAdd = true }
                    Button("Import from secrets.txt") { showingImportText = true }
                        .buttonStyle(.link)
                    Button("Import from QR Code image") { showingImportQR = true }
                        .buttonStyle(.link)
                }
                Spacer()
            } else {
                List {
                    ForEach(store.profiles) { profile in
                        OTPRow(profile: profile, tick: tick, onEdit: { editingProfile = profile })
                    }
                    .onDelete { indexSet in
                        for i in indexSet { store.delete(store.profiles[i]) }
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            // Bottom bar
            HStack {
                Button { showingImportText = true } label: {
                    Image(systemName: "doc.text")
                }
                .help("Import secrets.txt")

                Button { showingImportQR = true } label: {
                    Image(systemName: "qrcode")
                }
                .help("Import QR code image")

                Button { showingExport = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Export profiles")
                .disabled(store.profiles.isEmpty)

                Spacer()

                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                }
                .help("Add profile")
            }
            .padding(8)
        }
        .onReceive(timer) { _ in tick += 1 }
        .sheet(isPresented: $showingAdd) { AddProfileSheet() }
        .sheet(item: $editingProfile) { profile in EditProfileSheet(profile: profile) }
        .sheet(isPresented: $showingExport) { ExportSheet() }
        .fileImporter(isPresented: $showingImportText, allowedContentTypes: [.plainText]) { result in
            if case .success(let url) = result {
                _ = url.startAccessingSecurityScopedResource()
                _ = store.importFromFile(url)
                url.stopAccessingSecurityScopedResource()
            }
        }
        .fileImporter(isPresented: $showingImportQR, allowedContentTypes: [.png, .jpeg, .image]) { result in
            if case .success(let url) = result {
                _ = url.startAccessingSecurityScopedResource()
                _ = store.importFromQR(url)
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}

// MARK: - OTP Row

struct OTPRow: View {
    let profile: Profile
    let tick: Int
    let onEdit: () -> Void
    @State private var copied = false

    var code: String {
        _ = tick
        return TOTP.generate(secret: profile.secret) ?? "------"
    }

    var body: some View {
        HStack {
            // Validity indicator
            Circle()
                .fill(profile.isValid ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.headline)
                Text(code)
                    .font(.system(.title, design: .monospaced).bold())
                    .foregroundStyle(code == "------" ? .red : .primary)
            }
            Spacer()

            Button { onEdit() } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Edit profile")

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(copied ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .help("Copy code")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Timer Ring

struct TimerRing: View {
    let remaining: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(remaining) / 30.0)
                .stroke(remaining <= 5 ? Color.red : Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: remaining)
            Text("\(remaining)")
                .font(.caption2.monospacedDigit())
        }
    }
}

// MARK: - Add Profile

struct AddProfileSheet: View {
    @EnvironmentObject var store: ProfileStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var secret = ""
    @State private var pasteURI = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Profile").font(.headline)

            TextField("Profile name (e.g. GitHub)", text: $name)
                .textFieldStyle(.roundedBorder)
            SecureField("Secret key (Base32)", text: $secret)
                .textFieldStyle(.roundedBorder)

            Divider()
            Text("Or paste otpauth:// URI").font(.caption).foregroundStyle(.secondary)
            TextField("otpauth://totp/...", text: $pasteURI)
                .textFieldStyle(.roundedBorder)
                .onChange(of: pasteURI) { newValue in
                    if let parsed = QRCodeParser.parse(newValue) {
                        name = parsed.name
                        secret = parsed.secret
                    }
                }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    let trimmed = secret.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty, !trimmed.isEmpty else { return }
                    store.add(name: name, secret: trimmed)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || secret.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

// MARK: - Edit Profile

struct EditProfileSheet: View {
    @EnvironmentObject var store: ProfileStore
    @Environment(\.dismiss) var dismiss
    let profile: Profile
    @State private var name: String = ""
    @State private var secret: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Profile").font(.headline)
            TextField("Profile name", text: $name)
                .textFieldStyle(.roundedBorder)
            SecureField("Secret key (Base32)", text: $secret)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Delete", role: .destructive) {
                    store.delete(profile)
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    var updated = profile
                    updated.name = name
                    updated.secret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.update(updated)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || secret.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            name = profile.name
            secret = profile.secret
        }
    }
}

// MARK: - Export

struct ExportSheet: View {
    @EnvironmentObject var store: ProfileStore
    @Environment(\.dismiss) var dismiss
    @State private var password = ""
    @State private var showPlainExport = false
    @State private var showEncryptedExport = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Export Profiles").font(.headline)

            Button("Export as plain text (secrets.txt)") {
                showPlainExport = true
            }

            Divider()

            Text("Encrypted export").font(.subheadline)
            SecureField("Password for encryption", text: $password)
                .textFieldStyle(.roundedBorder)
            Button("Export encrypted backup") {
                showEncryptedExport = true
            }
            .disabled(password.count < 4)

            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(20)
        .frame(width: 360)
        .fileExporter(isPresented: $showPlainExport, document: TextDocument(text: store.exportPlainText()), contentType: .plainText, defaultFilename: "trueauth-secrets.txt") { _ in
            dismiss()
        }
        .fileExporter(isPresented: $showEncryptedExport, document: BinaryDocument(data: store.exportEncrypted(password: password) ?? Data()), contentType: .data, defaultFilename: "trueauth-backup.enc") { _ in
            dismiss()
        }
    }
}

// MARK: - Document types for export

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String

    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws {
        text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct BinaryDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
