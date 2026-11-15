#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Library/Developer/CommandLineTools}"
if [ -z "${SDK:-}" ]; then
    if [ -d "$DEVELOPER_DIR/SDKs/MacOSX26.5.sdk" ]; then
        SDK="$DEVELOPER_DIR/SDKs/MacOSX26.5.sdk"
    else
        SDK="$(xcrun --show-sdk-path 2>/dev/null || true)"
        if [ -z "$SDK" ] || [ ! -d "$SDK" ]; then
            SDK="$DEVELOPER_DIR/SDKs/MacOSX.sdk"
        fi
    fi
fi
ARCH="$(uname -m)"
if [ "$ARCH" != "arm64" ]; then
    echo "Error: Harness Sync requires Apple Silicon (arm64). Detected $ARCH." >&2
    exit 1
fi
mkdir -p .cache/modules
"$DEVELOPER_DIR/usr/bin/swiftc" -sdk "$SDK" -target "arm64-apple-macosx13.0" -parse-as-library -module-cache-path "$PWD/.cache/modules" Sources/BrandMark.swift Tools/MakeIcon.swift -o .cache/MakeIcon
.cache/MakeIcon .cache/AppIcon.iconset Resources/AppIcon.icns
"$DEVELOPER_DIR/usr/bin/swiftc" -sdk "$SDK" -target "arm64-apple-macosx13.0" -parse-as-library -module-cache-path "$PWD/.cache/modules" Sources/*.swift -o .cache/HarnessSync
STAGING="$(mktemp -d /tmp/harnesssync-build.XXXXXX)"
trap 'rm -rf "$STAGING"' EXIT
APP="$STAGING/Harness Sync.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# Write bytes into a fresh bundle to avoid inherited Finder/provider metadata.
python3 - "$PWD" "$APP" <<'PYBUILD'
import sys
from pathlib import Path
root, app = map(Path,sys.argv[1:])
for src,dst in [(".cache/HarnessSync","MacOS/HarnessSync"),("Resources/Info.plist","Info.plist"),("Resources/AppIcon.icns","Resources/AppIcon.icns"),("Resources/crowbot-mask.png","Resources/crowbot-mask.png"),("Resources/fireworks-mask.png","Resources/fireworks-mask.png"),("Resources/vertex-mask.png","Resources/vertex-mask.png"),("Resources/aistudio-mask.png","Resources/aistudio-mask.png"),("Resources/cerebras-mask.png","Resources/cerebras-mask.png"),("Resources/refuseless-mask.png","Resources/refuseless-mask.png"),("Resources/venice-mask.png","Resources/venice-mask.png"),("Resources/lutheos-mask.png","Resources/lutheos-mask.png"),("Resources/unaligned-mask.png","Resources/unaligned-mask.png"),("Resources/yeta-mask.png","Resources/yeta-mask.png"),("Resources/heimdallm-mask.png","Resources/heimdallm-mask.png"),("Resources/inferhub-mask.png","Resources/inferhub-mask.png")]:
    (app/"Contents"/dst).write_bytes((root/src).read_bytes())
(app/"Contents/MacOS/HarnessSync").chmod(0o755)
PYBUILD
codesign --force --sign - -r='designated => identifier "app.harnesssync.HarnessSync"' "$APP"
codesign --verify --strict "$APP"
ditto -c -k --norsrc --noextattr --keepParent "$APP" "$PWD/HarnessSync-app.zip"
ditto --norsrc --noextattr "$APP" "$PWD/Harness Sync.app"
rm -rf "/Applications/API Bar.app" "$PWD/API Bar.app" 2>/dev/null || true
ditto --norsrc --noextattr "$APP" "/Applications/Harness Sync.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/Harness Sync.app" 2>/dev/null || true
touch "/Applications/Harness Sync.app"
echo "Built Harness Sync.app and installed to /Applications/Harness Sync.app"
