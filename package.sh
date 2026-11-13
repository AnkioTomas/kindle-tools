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
cp -R documents ankio-tools README.md LICENSE "$STAGE/$NAME/"
# 备用入口：给只有 KUAL、书库不显示 .sh 的设备，复制 extensions 即可出现在 KUAL 菜单
EXT="$STAGE/$NAME/extensions/ankio-tools"
mkdir -p "$EXT"
cp ankio-tools/config.xml "$EXT/config.xml"
python3 - ankio-tools/menu.json "$EXT/menu.json" <<'PY'
import json, sys
def fix(items):
    for i in items:
        if "items" in i:
            fix(i["items"])
        elif i.get("action") == "./handoff_koreader.sh":
            i["action"] = "/mnt/us/koreader/koreader.sh"
            i["params"] = "--kual" if i.get("params") == "normal" else "--kual --framework_stop"
        elif i.get("action", "").startswith("./"):
            i["action"] = "/mnt/us/ankio-tools/" + i["action"][2:]
d = json.load(open(sys.argv[1]))
fix(d["items"])
json.dump(d, open(sys.argv[2], "w"), ensure_ascii=False, indent=2)
PY
find "$STAGE" \( -name .DS_Store -o -name '._*' \) -delete
chmod 755 "$STAGE/$NAME"/documents/*.sh "$STAGE/$NAME"/ankio-tools/*.sh "$STAGE/$NAME"/ankio-tools/kual-next/launch.sh "$STAGE/$NAME"/ankio-tools/kual-next/bin/kual-next

for f in "$STAGE/$NAME"/documents/*.sh "$STAGE/$NAME"/ankio-tools/*.sh "$STAGE/$NAME"/ankio-tools/kual-next/launch.sh; do
	sh -n "$f" || { echo "语法错误: $f" >&2; exit 1; }
done

rm -f "$OUT_DIR/$NAME.zip"
(cd "$STAGE" && zip -qr -X "$OUT_DIR/$NAME.zip" "$NAME")
echo "$OUT_DIR/$NAME.zip"
