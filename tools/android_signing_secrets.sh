#!/usr/bin/env bash
# Kalıcı Android imza anahtarını GitHub Actions gizli değişkenlerine yükler.
# Anahtar ~/.config/golge-oyunu/ altında durur (repoda değil); bir kez
# çalıştırmak yeter.
set -euo pipefail
D="${HOME}/.config/golge-oyunu"
PW="$(grep '^storePassword=' "$D/key.properties" | cut -d= -f2)"
base64 -w0 "$D/golge-upload.jks" | gh secret set ANDROID_KEYSTORE_BASE64
printf '%s' "$PW" | gh secret set ANDROID_KEYSTORE_PASSWORD
printf '%s' "$PW" | gh secret set ANDROID_KEY_PASSWORD
printf 'golge' | gh secret set ANDROID_KEY_ALIAS
gh secret list
