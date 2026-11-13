#!/bin/sh
# 打包为 Ankio-Kindle-Tools-<版本>.zip，默认输出到 ~/Downloads。
# 用法: ./package.sh [输出目录]
set -eu
cd "$(dirname "$0")"

OUT_DIR=${1:-$HOME/Downloads}
VERSION=$(sed -n 's#.*<version>\(.*\)</version>.*#\1#p' ankio-tools/config.xml | head -1)
NAME=Ankio-Kindle-Tools-${VERSION:-dev}
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/$NAME" "$OUT_DIR"
cp -R documents ankio-tools README.md "$STAGE/$NAME/"
find "$STAGE" \( -name .DS_Store -o -name '._*' \) -delete
chmod 755 "$STAGE/$NAME"/documents/*.sh "$STAGE/$NAME"/ankio-tools/*.sh "$STAGE/$NAME"/ankio-tools/kual-next/launch.sh "$STAGE/$NAME"/ankio-tools/kual-next/bin/kual-next

for f in "$STAGE/$NAME"/documents/*.sh "$STAGE/$NAME"/ankio-tools/*.sh "$STAGE/$NAME"/ankio-tools/kual-next/launch.sh; do
	sh -n "$f" || { echo "语法错误: $f" >&2; exit 1; }
done

rm -f "$OUT_DIR/$NAME.zip"
(cd "$STAGE" && zip -qr -X "$OUT_DIR/$NAME.zip" "$NAME")
echo "$OUT_DIR/$NAME.zip"
