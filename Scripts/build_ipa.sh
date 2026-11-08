#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE="$ROOT/Export/ZiWeiDaily.xcarchive"
STAGE="$ROOT/Export/ipa-stage"
UNSIGNED_IPA="$ROOT/Export/ZiWeiDaily-unsigned.ipa"

cd "$ROOT"
swift test --disable-sandbox
xcodegen generate --spec "$ROOT/project.yml"

rm -rf "$ARCHIVE" "$STAGE"
xcodebuild \
  -IDEPackageSupportDisableManifestSandbox=1 \
  -IDEPackageSupportDisablePluginExecutionSandbox=1 \
  -project "$ROOT/ZiWeiDaily.xcodeproj" \
  -scheme ZiWeiDaily \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  -derivedDataPath "$ROOT/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  'OTHER_SWIFT_FLAGS=$(inherited) -disable-sandbox' \
  archive

mkdir -p "$STAGE/Payload"
cp -R "$ARCHIVE/Products/Applications/ZiWeiDaily.app" "$STAGE/Payload/ZiWeiDaily.app"
cd "$STAGE"
xattr -cr Payload
rm -f "$UNSIGNED_IPA"
COPYFILE_DISABLE=1 zip -qry "$UNSIGNED_IPA" Payload

print "Unsigned IPA exported to $UNSIGNED_IPA"
print "Sign it with your Apple Development profile before installing on a registered device."
