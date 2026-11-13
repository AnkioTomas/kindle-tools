#!/bin/sh
# Name: 恢复自动更新
# Author: Ankio
# Icon: /mnt/us/ankio-tools/icons/restore_ota.png
# DontUseFBInk
say() { printf '%s\n' "$1"; command -v eips >/dev/null 2>&1 && eips 1 22 "$1" >/dev/null 2>&1; sleep 4; }
end() { say "$1"; exit 0; }
[ -r /proc/cmdline ] && grep -q androidboot.veritymode /proc/cmdline && end "失败: verity/rootless, 未改"
MR=$(command -v mntroot 2>/dev/null)
[ -z "$MR" ] && [ -x /usr/sbin/mntroot ] && MR=/usr/sbin/mntroot
[ -n "$MR" ] || end "失败: 无mntroot, 未改"
RW=0
ro() { [ "$RW" = 1 ] || return 0; if "$MR" ro; then RW=0; else printf '%s\n' "错误: mntroot ro失败, 请立刻手动执行 mntroot ro"; command -v eips >/dev/null 2>&1 && eips 1 23 "错误: 请手动mntroot ro"; fi; }
trap ro EXIT
trap 'ro; exit 0' INT TERM HUP
ok=0; need=0
for b in /usr/bin/otaupd /usr/bin/otav3; do
	k=$b.bck
	for p in "$b" "$k"; do
		[ -L "$p" ] && end "失败: 符号链接 $p"
		[ -e "$p" ] && [ ! -f "$p" ] && end "失败: 非普通文件 $p"
	done
	[ -f "$b" ] && [ -f "$k" ] && end "失败: 冲突 $b 与 $k"
	[ -f "$k" ] && { ok=1; need=1; }
	[ -f "$b" ] && ok=1
done
[ "$ok" = 1 ] || end "失败: 未找到otaupd/otav3, 未改"
[ "$need" = 1 ] || end "已是恢复状态, 未改动"
CA=; [ -x /bin/chattr.e2fsprogs ] && CA=/bin/chattr.e2fsprogs; [ -z "$CA" ] && [ -x /bin/chattr ] && CA=/bin/chattr
"$MR" rw || end "失败: mntroot rw, 未改"
RW=1
for b in /usr/bin/otaupd /usr/bin/otav3; do
	k=$b.bck
	[ -f "$k" ] || continue
	[ -n "$CA" ] && { "$CA" -i "$k" || end "失败: chattr -i $k"; }
	mv "$k" "$b" || end "失败: 恢复 $k"
done
end "已恢复自动更新。请手动重启。"
