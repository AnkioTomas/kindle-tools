#!/bin/sh
# Name: 开启KOReader自启动
# Author: Ankio
# Icon: /mnt/us/script-icons/enable_koreader_autostart.png
# DontUseFBInk
say() { printf '%s\n' "$1"; command -v eips >/dev/null 2>&1 && eips 1 22 "$1" >/dev/null 2>&1; sleep 4; }
end() { ro; say "$1"; exit 0; }
FLAG=/mnt/us/DISABLE_KOREADER_AUTOSTART
KR=/mnt/us/koreader/koreader.sh
DEST=/mnt/us/koreader/koreader_autostart_worker.sh
CONF=/etc/upstart/koreader_autostart.conf
MARK=KOREADER_AUTOSTART_HOOK
RW=0
ro() { [ "$RW" = 1 ] || return 0; if "$MR" ro; then RW=0; else printf '%s\n' "错误: mntroot ro失败, 请立刻手动执行 mntroot ro"; command -v eips >/dev/null 2>&1 && eips 1 23 "错误: 请手动mntroot ro"; fi; }
[ -f "$KR" ] || end "失败: 未找到koreader.sh, 未改"
[ -L "$DEST" ] && end "失败: 符号链接 worker, 未改"
[ -e "$DEST" ] && [ ! -f "$DEST" ] && end "失败: 非普通文件 worker, 未改"
SRC=
for c in /mnt/us/documents/koreader_autostart_worker.sh "$DEST"; do
	[ -L "$c" ] && continue
	[ -f "$c" ] && [ -r "$c" ] && SRC=$c && break
done
[ -n "$SRC" ] || end "失败: 请先把worker放到documents或koreader目录, 未改"
[ -r /proc/cmdline ] && grep -q androidboot.veritymode /proc/cmdline && end "失败: verity/rootless, 未改"
MR=$(command -v mntroot 2>/dev/null)
[ -z "$MR" ] && [ -x /usr/sbin/mntroot ] && MR=/usr/sbin/mntroot
[ -n "$MR" ] || end "失败: 无mntroot, 未改"
[ -L "$CONF" ] && end "失败: 符号链接 $CONF"
[ -e "$CONF" ] && [ ! -f "$CONF" ] && end "失败: 非普通文件 $CONF"
[ -f "$CONF" ] && { grep -q "$MARK" "$CONF" || end "失败: 已有未知同名upstart作业, 未改"; }
trap ro EXIT
trap 'ro; exit 0' INT TERM HUP
if [ "$SRC" != "$DEST" ]; then
	cp "$SRC" "$DEST" || end "失败: 无法写入worker"
fi
chmod 755 "$DEST" 2>/dev/null || true
"$MR" rw || end "失败: mntroot rw, 未改"
RW=1
cat > "$CONF" << 'EOF'
# KOREADER_AUTOSTART_HOOK
description "KOReader one-shot autostart no framework"
# OTA overwrites /etc/upstart; re-run this scriptlet after OTA.
# Do not stop on lab126_gui/framework: --framework_stop stops the gui on purpose.
start on framework_ready and started lab126_gui and mounted_userstore
stop on runlevel [06]
task
script
	exec /bin/sh /mnt/us/koreader/koreader_autostart_worker.sh
end script
EOF
[ -s "$CONF" ] && grep -q "$MARK" "$CONF" || end "失败: 写入upstart作业失败"
chmod 644 "$CONF" 2>/dev/null || true
command -v initctl >/dev/null 2>&1 && initctl reload-configuration >/dev/null 2>&1 || true
rm -f "$FLAG"
end "已安装自启动, 未立即运行。请手动重启。OTA后需重装。白屏时在USB根目录新建DISABLE_KOREADER_AUTOSTART"
