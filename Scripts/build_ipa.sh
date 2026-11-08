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
# 用 -X 去掉 Info-ZIP 的 0x5455/0x7875 附加字段，避免部分签名工具解析失败
COPYFILE_DISABLE=1 zip -qryX "$UNSIGNED_IPA" Payload

# 自检：结构 + CRC
unzip -tq "$UNSIGNED_IPA" >/dev/null && print "IPA integrity OK"
unzip -l "$UNSIGNED_IPA" | grep -q "Payload/ZiWeiDaily.app/Info.plist" && print "Payload structure OK"

print "Unsigned IPA exported to $UNSIGNED_IPA"
print "Sign it with your Apple Development profile before installing on a registered device."
