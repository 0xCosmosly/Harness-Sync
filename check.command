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
mkdir -p .cache/checks
# Tests must never touch the real credential vault, balance file, or Keychain.
TEST_STATE="$(mktemp -d /tmp/harnesssync-check.XXXXXX)"
export HARNESSSYNC_VAULT_DIR="$TEST_STATE/vault"
export HARNESSSYNC_DATA_DIR="$TEST_STATE/data"
export HARNESSSYNC_ICLOUD_DIR="$TEST_STATE/icloud"
export HARNESSSYNC_OPENCODE_FILE="$TEST_STATE/opencode.json"
export HARNESSSYNC_PI_DIR="$TEST_STATE/pi_agent"
export HARNESSSYNC_OMP_DIR="$TEST_STATE/omp_agent"
export HARNESSSYNC_T3_DIR="$TEST_STATE/t3_userdata"
export APIBAR_VAULT_DIR="$HARNESSSYNC_VAULT_DIR"
export APIBAR_DATA_DIR="$HARNESSSYNC_DATA_DIR"
export APIBAR_ICLOUD_DIR="$HARNESSSYNC_ICLOUD_DIR"
export APIBAR_OPENCODE_FILE="$HARNESSSYNC_OPENCODE_FILE"
export APIBAR_PI_DIR="$HARNESSSYNC_PI_DIR"
export APIBAR_OMP_DIR="$HARNESSSYNC_OMP_DIR"
export APIBAR_T3_DIR="$HARNESSSYNC_T3_DIR"
mkdir -p "$HARNESSSYNC_VAULT_DIR" "$HARNESSSYNC_DATA_DIR" "$HARNESSSYNC_ICLOUD_DIR" "$HARNESSSYNC_PI_DIR" "$HARNESSSYNC_OMP_DIR" "$HARNESSSYNC_T3_DIR"
swiftc -sdk "$SDK" -target "arm64-apple-macosx13.0" -parse-as-library -module-cache-path "$PWD/.cache/modules" Sources/BrandMark.swift Sources/Balance.swift Sources/Provider.swift Sources/Credentials.swift Sources/GoogleWebClientKeys.swift Sources/SessionHTTP.swift Sources/UnalignedProvider.swift Sources/YetaProvider.swift Sources/HeimdallmProvider.swift Sources/InferHubProvider.swift Sources/GoogleProvider.swift Sources/CrowbotProvider.swift Sources/AppUpdater.swift Sources/Changelog.swift Sources/CodexBarPacing.swift Sources/SyncChangeLog.swift Sources/AFMSummarizer.swift Tests/Checks.swift -o .cache/checks/HarnessSyncChecks
.cache/checks/HarnessSyncChecks
plutil -lint Resources/Info.plist
UI_SOURCES=()
for source in Sources/*.swift; do
    if [[ "$source" != "Sources/Main.swift" ]]; then UI_SOURCES+=("$source"); fi
done
swiftc -sdk "$SDK" -target "arm64-apple-macosx13.0" -parse-as-library -module-cache-path "$PWD/.cache/modules" "${UI_SOURCES[@]}" Tests/UIInteractionChecks.swift -o .cache/checks/UIInteractionChecks
.cache/checks/UIInteractionChecks --diagnostics "$PWD/.cache/checks/interface.json"
rm -rf "$TEST_STATE"
