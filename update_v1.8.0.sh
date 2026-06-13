#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════╗"
echo "║  CLONADA v1.8.0 UPDATE                       ║"
echo "║  Cloud Training Pipeline Fix                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

INSTALL_DIR="$HOME/Clonada"

echo "[1/3] Downloading updated plugin..."
cd /tmp
curl -sL "https://github.com/anirudhatalmale6-alt/clonada/releases/download/beta-macos/Clonada-beta-macOS.zip" -o Clonada-beta-macOS.zip
unzip -qo Clonada-beta-macOS.zip -d Clonada-update

echo "[2/3] Installing plugin files..."
# VST3
if [ -d "Clonada-update/Clonada.vst3" ]; then
    rm -rf "/Library/Audio/Plug-Ins/VST3/Clonada.vst3"
    cp -r "Clonada-update/Clonada.vst3" "/Library/Audio/Plug-Ins/VST3/"
    echo "  ✓ VST3 updated"
fi
# AU
if [ -d "Clonada-update/Clonada.component" ]; then
    rm -rf "/Library/Audio/Plug-Ins/Components/Clonada.component"
    cp -r "Clonada-update/Clonada.component" "/Library/Audio/Plug-Ins/Components/"
    echo "  ✓ AU updated"
fi
# CLAP
if [ -d "Clonada-update/Clonada.clap" ]; then
    rm -rf "/Library/Audio/Plug-Ins/CLAP/Clonada.clap"
    cp -r "Clonada-update/Clonada.clap" "/Library/Audio/Plug-Ins/CLAP/"
    echo "  ✓ CLAP updated"
fi
# Standalone
if [ -d "Clonada-update/Clonada.app" ]; then
    rm -rf "/Applications/Clonada.app"
    cp -r "Clonada-update/Clonada.app" "/Applications/"
    echo "  ✓ Standalone updated"
fi

echo "[3/3] Updating cloud engine..."
# Download updated cloud bridge
curl -sL "https://raw.githubusercontent.com/anirudhatalmale6-alt/clonada/main/python/clonada_cloud_bridge.py" -o "$INSTALL_DIR/clonada_cloud_bridge.py"
curl -sL "https://raw.githubusercontent.com/anirudhatalmale6-alt/clonada/main/python/lib/license_client.py" -o "$INSTALL_DIR/lib/license_client.py" 2>/dev/null
mkdir -p "$INSTALL_DIR/lib"
curl -sL "https://raw.githubusercontent.com/anirudhatalmale6-alt/clonada/main/python/lib/license_client.py" -o "$INSTALL_DIR/lib/license_client.py"
curl -sL "https://raw.githubusercontent.com/anirudhatalmale6-alt/clonada/main/python/lib/__init__.py" -o "$INSTALL_DIR/lib/__init__.py"

# Create a Python-based engine launcher (since PyInstaller binary can't be built remotely)
cat > "$INSTALL_DIR/start_engine.sh" << 'LAUNCHER'
#!/bin/bash
cd "$(dirname "$0")"
if command -v python3 &>/dev/null; then
    python3 -m pip install --quiet pyzmq requests numpy soundfile 2>/dev/null
    python3 clonada_cloud_bridge.py --models-dir "$HOME/Clonada/models" "$@"
else
    echo "Python 3 is required. Install from https://python.org"
    exit 1
fi
LAUNCHER
chmod +x "$INSTALL_DIR/start_engine.sh"
echo "  ✓ Cloud engine updated"

# Remove quarantine
xattr -rd com.apple.quarantine /Library/Audio/Plug-Ins/VST3/Clonada.vst3 2>/dev/null
xattr -rd com.apple.quarantine /Library/Audio/Plug-Ins/Components/Clonada.component 2>/dev/null
xattr -rd com.apple.quarantine /Library/Audio/Plug-Ins/CLAP/Clonada.clap 2>/dev/null
xattr -rd com.apple.quarantine /Applications/Clonada.app 2>/dev/null

# Clear AU cache
killall -9 AudioComponentRegistrar 2>/dev/null
rm -rf ~/Library/Caches/AudioUnitCache 2>/dev/null
rm -f ~/Library/Preferences/com.apple.audio.InfoHelper.plist 2>/dev/null

# Cleanup
rm -rf /tmp/Clonada-update /tmp/Clonada-beta-macOS.zip

echo ""
echo "✅ Clonada v1.8.0 update complete!"
echo ""
echo "To start the engine: cd ~/Clonada && ./start_engine.sh"
echo "Then open Logic Pro and reload the Clonada plugin."
