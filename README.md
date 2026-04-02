# TrueAuth

A lightweight macOS TOTP 2FA authenticator built with SwiftUI. No cloud sync, no accounts — your secrets stay on your machine, encrypted.

![macOS](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Download

Go to [Releases](https://github.com/nghiack7/TrueAuth/releases) and download the latest `.dmg` file.

## Features

| Feature | Description |
|---------|-------------|
| **TOTP Generation** | RFC 6238 compliant, auto-refreshes every 30 seconds with countdown ring |
| **QR Code Import** | Select a QR code image file — the app reads the `otpauth://` URI automatically |
| **Manual Entry** | Add profiles by typing a name and Base32 secret key |
| **Paste URI** | Paste an `otpauth://totp/...` URI directly when adding a profile |
| **Edit Profiles** | Modify name and secret of any existing profile |
| **Delete Profiles** | Remove profiles you no longer need |
| **Export (Plain)** | Export all profiles as `NAME=SECRET` text file for backup |
| **Export (Encrypted)** | Password-protected encrypted backup using ChaChaPoly |
| **Import (Text)** | Import from `secrets.txt` file (`NAME=SECRET` format, one per line) |
| **Import (Encrypted)** | Restore from an encrypted backup with your password |
| **Encrypted Storage** | Secrets are encrypted at rest using ChaChaPoly; encryption key stored in macOS Keychain |
| **Secret Validation** | Green/red dot indicator showing if each secret is valid Base32 |
| **Copy to Clipboard** | One-click copy of the current OTP code |

## Install

### From DMG (recommended)

1. Download `TrueAuth.dmg` from [Releases](https://github.com/nghiack7/TrueAuth/releases)
2. Open the DMG
3. Drag **TrueAuth** into your **Applications** folder
4. Launch TrueAuth

### Build from source

```bash
git clone https://github.com/nghiack7/TrueAuth.git
cd TrueAuth
swift build -c release

# Create .app bundle
mkdir -p TrueAuth.app/Contents/MacOS TrueAuth.app/Contents/Resources
cp .build/release/TrueAuth TrueAuth.app/Contents/MacOS/
cp Info.plist TrueAuth.app/Contents/
cp Resources/AppIcon.icns TrueAuth.app/Contents/Resources/
open TrueAuth.app
```

## Usage

### Adding a profile

1. Click the **+** button at the bottom
2. Enter a **profile name** (e.g., "GitHub", "AWS")
3. Enter the **Base32 secret key** (from your service's 2FA setup page)
4. Click **Add**

**Tip:** You can also paste an `otpauth://totp/...` URI in the URI field — name and secret will be auto-filled.

### Importing from QR code

1. Save the QR code as an image file (screenshot or download)
2. Click the **QR code** button at the bottom bar
3. Select the image file
4. The profile is automatically created

### Importing from secrets.txt

If you have a `secrets.txt` file with format:

```
GitHub=JBSWY3DPEHPK3PXP
AWS_Console=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ
```

1. Click the **document** icon at the bottom bar
2. Select your `secrets.txt` file
3. All profiles are imported

### Editing a profile

Click the **pencil** icon next to any profile to edit its name or secret.

### Exporting profiles

1. Click the **export** icon at the bottom bar
2. Choose **plain text** (unencrypted `NAME=SECRET` format) or **encrypted backup** (password-protected)
3. Save the file

## Security

- **Encrypted at rest**: All secrets are encrypted using [ChaChaPoly](https://developer.apple.com/documentation/cryptokit/chachapoly) (from Apple's CryptoKit)
- **Keychain-stored key**: The encryption key is stored in macOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — it never leaves your Mac
- **No network access**: The app makes zero network requests. Everything is local.
- **No cloud sync**: Your secrets are never uploaded anywhere
- **Auto-migration**: If upgrading from an older version with plaintext storage, secrets are automatically encrypted and the old file is removed

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 13+ (Ventura) | Supported |
| Windows | Not supported (uses macOS-native APIs) |
| Linux | Not supported (uses macOS-native APIs) |

This app uses macOS-specific frameworks (AppKit, Security/Keychain, CoreImage) that have no cross-platform equivalent.

## How it works

1. **TOTP Algorithm**: Implements [RFC 6238](https://datatracker.ietf.org/doc/html/rfc6238) — HMAC-SHA1 based time-based one-time passwords
2. **Base32 Decoding**: Custom decoder for the secret keys (standard TOTP encoding)
3. **30-second window**: Codes rotate every 30 seconds with a visual countdown ring
4. **QR Parsing**: Uses CoreImage's `CIDetector` to read QR codes from image files, then parses the `otpauth://` URI

## License

MIT
