#!/bin/sh
# Name: 恢复锁屏广告
# Author: Ankio
# Icon: /mnt/us/ankio-tools/icons/restore_ads.png
# DontUseFBInk
. /mnt/us/ankio-tools/lib.sh
end() { say "$1"; exit 0; }
A=/mnt/us/system/.assets
[ -L "$A" ] && end "失败: 符号链接 $A, 未改"
if [ -f "$A" ] && [ ! -s "$A" ]; then
	rm -f "$A" || end "失败: 无法删除占位文件"
	end "已取消广告拦截。请重启生效。"
fi
end "已是未拦截状态, 未改动"
