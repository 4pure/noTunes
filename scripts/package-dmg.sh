#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="noTunes"
APP_NAME="noTunes"
PBXPROJ="noTunes.xcodeproj/project.pbxproj"

VERSION=$(python3 - <<PY
import re, pathlib
text = pathlib.Path("$PBXPROJ").read_text()
m = re.search(r"MARKETING_VERSION = ([^;]+);", text)
print(m.group(1).strip().strip('"') if m else "0.0")
PY
)
BUILD=$(python3 - <<PY
import re, pathlib
text = pathlib.Path("$PBXPROJ").read_text()
m = re.search(r"CURRENT_PROJECT_VERSION = ([^;]+);", text)
print(m.group(1).strip().strip('"') if m else "0")
PY
)

# Usage: ./scripts/package-dmg.sh [universal|arm|intel]
# Default: universal
REQUESTED="${1:-universal}"
case "$REQUESTED" in
  universal|arm|intel) ;;
  *)
    echo "Usage: $0 [universal|arm|intel]" >&2
    exit 1
    ;;
esac

section() {
  echo
  echo "======== $* ========"
  echo
}

print_build_result() {
  local out_dir="$1"
  local artifact="$2"
  echo
  echo "产物目录：${out_dir}"
  echo "可执行文件：${artifact}"
  echo
}

archs_for_label() {
  case "$1" in
    arm) echo "arm64" ;;
    intel) echo "x86_64" ;;
    universal) echo "arm64 x86_64" ;;
  esac
}

expected_archs_for_label() {
  case "$1" in
    arm) echo "arm64" ;;
    intel) echo "x86_64" ;;
    universal) echo "x86_64 arm64" ;;
  esac
}

package_one() {
  local label="$1"
  local archs
  archs="$(archs_for_label "$label")"
  local derived="build/ReleaseDerivedData-${label}"
  local stage="dist/staging-${label}"
  local STEPS=2
  local STEP=0

  next_section() {
    STEP=$((STEP + 1))
    section "[$STEP/$STEPS] $*"
  }

  next_section "xcodebuild Release ${label}"
  rm -rf "$derived" "$stage"

  xcodebuild \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$derived" \
    ARCHS="$archs" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=YES \
    build

  local app="$derived/Build/Products/Release/${APP_NAME}.app"
  test -d "$app"

  local binary
  binary="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")"
  local actual
  actual="$(lipo -archs "$app/Contents/MacOS/$binary" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ *$//')"
  local expected
  expected="$(expected_archs_for_label "$label" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ *$//')"
  if [[ "$actual" != "$expected" ]]; then
    echo "error: expected arches [$expected], got [$actual]" >&2
    exit 1
  fi

  next_section "create dmg ${label}"
  mkdir -p "$stage"
  ditto "$app" "$stage/${APP_NAME}.app"
  ln -sf /Applications "$stage/Applications"

  local dmg_path="dist/${APP_NAME}-${VERSION}-${label}.dmg"
  rm -f "$dmg_path"
  diskutil image create from \
    --format UDZO \
    --volumeName "${APP_NAME} ${VERSION} (${label})" \
    "$stage" \
    "$ROOT/$dmg_path"

  rm -rf "$stage"

  local artifact="$ROOT/$dmg_path"
  if [[ ! -f "$artifact" ]]; then
    echo "DMG not found: $artifact" >&2
    exit 1
  fi
  print_build_result "$ROOT/dist" "$artifact"
}

mkdir -p dist
# Drop legacy arch suffixes from earlier script versions
rm -f dist/${APP_NAME}-*-arm64.dmg dist/${APP_NAME}-*-x86_64.dmg

package_one "$REQUESTED"
