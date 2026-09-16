#!/usr/bin/env bash
# Archive Release + upload su App Store Connect (TestFlight), con esito verificato.
#   scripts/release.sh            usa CURRENT_PROJECT_VERSION di project.yml
# Prerequisiti: tree pulito, record app su ASC (scripts/asc.py app), xcodegen, jq.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
LOG_DIR="$HOME/focus-tracker-logs"; mkdir -p "$LOG_DIR" build
fail() { echo "[release] BLOCCATO: $*" >&2; exit 1; }
command -v xcodegen >/dev/null || fail "xcodegen mancante (brew install xcodegen)"
[[ -z "$(git status --porcelain)" ]] || fail "working tree sporco: committa prima"
BUILD="$(grep -E '^\s*CURRENT_PROJECT_VERSION:' project.yml | awk '{print $2}')"
MARKETING="$(grep -E '^\s*MARKETING_VERSION:' project.yml | awk '{print $2}')"
echo "[release] $MARKETING ($BUILD)"
python3 scripts/asc.py app >&2
python3 scripts/asc.py assert-free "$BUILD" >&2
eval "$(python3 scripts/asc.py env)"
xcodegen generate >/dev/null
ARCHIVE="build/FocusTracker-$BUILD.xcarchive"; rm -rf "$ARCHIVE"
echo "[release] archive → $LOG_DIR/archive-$BUILD.log"
xcodebuild archive -project FocusTracker.xcodeproj -scheme FocusTracker -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  > "$LOG_DIR/archive-$BUILD.log" 2>&1 || { tail -30 "$LOG_DIR/archive-$BUILD.log"; fail "archive fallito"; }
BUILT="$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' "$ARCHIVE/Info.plist")"
[[ "$BUILT" == "$BUILD" ]] || fail "archive dichiara build $BUILT, atteso $BUILD"
echo "[release] upload → $LOG_DIR/export-$BUILD.log"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "build/FocusTracker-$BUILD-export" \
  -exportOptionsPlist ExportOptions-AppStore.plist -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  > "$LOG_DIR/export-$BUILD.log" 2>&1 || { tail -30 "$LOG_DIR/export-$BUILD.log"; fail "upload fallito"; }
# copia per simbolizzare i crash: va tenuta anche quando si pulisce il disco
DEST="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)"; mkdir -p "$DEST"; rm -rf "$DEST/$(basename "$ARCHIVE")"; cp -R "$ARCHIVE" "$DEST/"
echo "[release] attendo l'esito su ASC (fino a 30 min)"
STATE="$(python3 scripts/asc.py wait-build "$BUILD")" || fail "build $BUILD in stato $STATE"
python3 scripts/asc.py internal-group >&2
echo "[release] fatto: $MARKETING ($BUILD) → $STATE, gruppo interno allineato"
