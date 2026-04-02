# TrueAuth

A lightweight macOS TOTP 2FA authenticator built with SwiftUI.

## Features

- **TOTP Code Generation** — RFC 6238 compliant, auto-refreshes every 30 seconds
- **QR Code Import** — Import from QR code images (otpauth:// URI)
- **Manual Entry** — Add profiles with name + Base32 secret
- **Edit Profiles** — Modify name and secret of existing profiles
- **Export/Import** — Plain text or password-encrypted backup
- **Encrypted Storage** — Secrets encrypted at rest using ChaChaPoly with Keychain-stored key
- **Secret Validation** — Visual indicator for valid/invalid secrets
- **Copy to Clipboard** — One-click copy OTP codes

## Build

```bash
swift build -c release
```

## Install as .app

```bash
mkdir -p TrueAuth.app/Contents/MacOS
cp .build/release/TrueAuth TrueAuth.app/Contents/MacOS/
cp Info.plist TrueAuth.app/Contents/
open TrueAuth.app
```

## Import from existing secrets.txt

Format: `PROFILE_NAME=BASE32SECRET` (one per line)
