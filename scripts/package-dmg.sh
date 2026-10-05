#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

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

echo "==> Packaging ${APP_NAME} ${VERSION} (${BUILD})"

rm -rf build/ReleaseDerivedData dist/staging
mkdir -p dist
rm -f dist/${APP_NAME}-*.dmg dist/${APP_NAME}-*.zip
rm -rf dist/${APP_NAME}.app

xcodebuild \
  -scheme "${APP_NAME}" \
  -configuration Release \
  -derivedDataPath build/ReleaseDerivedData \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  build

APP="build/ReleaseDerivedData/Build/Products/Release/${APP_NAME}.app"
test -d "$APP"

STAGE="dist/staging"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/${APP_NAME}.app"
ln -sf /Applications "$STAGE/Applications"

DMG_PATH="dist/${APP_NAME}-${VERSION}.dmg"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "${APP_NAME} ${VERSION}" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGE"
ls -lh "$DMG_PATH"
echo "Done: ${ROOT}/${DMG_PATH}"
