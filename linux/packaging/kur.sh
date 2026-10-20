#!/usr/bin/env bash
# Gölge Oyunu'nu bu kullanıcı için uygulama menüsüne ekler (Sâye ikonuyla).
# Paket klasöründe ikonlu bir başlatıcı da oluşturur. Kök izni gerekmez.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
ID="com.erkanoz.golge"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
APP_DIR="$HOME/.local/share/applications"
mkdir -p "$ICON_DIR" "$APP_DIR"
cp "$DIR/golge.png" "$ICON_DIR/$ID.png"
cat > "$APP_DIR/$ID.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Gölge Oyunu
Name[en]=Shadow Play
Comment=Hayal perdesinde bir gölgenin yolculuğu
Comment[en]=A shadow's journey behind the screen
Exec="$DIR/golge"
Path=$DIR
Icon=$ID
Terminal=false
Categories=Game;AdventureGame;
StartupWMClass=$ID
DESKTOP
# Paket klasöründe ikonuyla görünen başlatıcı.
cp "$APP_DIR/$ID.desktop" "$DIR/Gölge Oyunu.desktop"
chmod +x "$DIR/Gölge Oyunu.desktop"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
# KDE menü önbelleği
for k in kbuildsycoca6 kbuildsycoca5; do
  command -v "$k" >/dev/null 2>&1 && "$k" >/dev/null 2>&1 && break
done
true
echo "Gölge Oyunu uygulama menüsüne eklendi."
