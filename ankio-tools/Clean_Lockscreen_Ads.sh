#!/bin/sh
# Name: 清理锁屏广告
# Author: Ankio
# Icon: /mnt/us/ankio-tools/icons/clean_ads.png
# DontUseFBInk
. /mnt/us/ankio-tools/lib.sh
end() { say "$1"; exit 0; }
A=/mnt/us/system/.assets
BAK=/mnt/us/system/.assets.ankio-bak
[ -L "$A" ] && end "失败: 符号链接 $A, 未改"
if [ -f "$A" ] && [ ! -s "$A" ]; then
	end "已是清理状态, 未改动"
fi
mkdir -p /mnt/us/system 2>/dev/null
if [ -d "$A" ]; then
	rm -rf "$BAK" 2>/dev/null
	mv "$A" "$BAK" || end "失败: 无法移走广告缓存"
	rm -rf "$BAK" 2>/dev/null
elif [ -e "$A" ]; then
	rm -f "$A" || end "失败: 无法清理广告缓存"
fi
: > "$A" || end "失败: 无法创建占位文件"
[ -f "$A" ] || end "失败: 无法创建占位文件"
end "已清理锁屏广告并阻止再次下载。请重启生效。仅对带特价广告的机型有效。"
