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
xattr -cr "$STAGE/Payload"

# 用 Scripts/pack_ipa.py 自己写 zip 结构：
# 不写附加字段、不写目录条目，规避 SSZipArchive / minizip 的解析兼容问题
python3 "$ROOT/Scripts/pack_ipa.py" "$STAGE/Payload/ZiWeiDaily.app" "$UNSIGNED_IPA" --deflate
python3 "$ROOT/Scripts/pack_ipa.py" "$STAGE/Payload/ZiWeiDaily.app" "$ROOT/Export/ZiWeiDaily-unsigned-store.ipa" --store --no-dirs

# 自检：结构 + CRC + 附加字段必须为 0
for f in "$UNSIGNED_IPA" "$ROOT/Export/ZiWeiDaily-unsigned-store.ipa"; do
  unzip -tq "$f" >/dev/null
  unzip -l "$f" | grep -q "Payload/ZiWeiDaily.app/Info.plist"
  if unzip -l "$f" | grep -qE "__MACOSX|\.DS_Store"; then
    print "包内含 macOS 垃圾文件：$f"; exit 1
  fi
  print "OK $(basename "$f") $(stat -f%z "$f") bytes"
done

print "Unsigned IPA exported to $UNSIGNED_IPA"
print "Sign it with your Apple Development profile before installing on a registered device."
