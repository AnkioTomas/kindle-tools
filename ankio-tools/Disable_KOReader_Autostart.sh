#!/bin/sh
# Name: 关闭KOReader自启动
# Author: Ankio
# Icon: /mnt/us/ankio-tools/icons/disable_koreader_autostart.png
# DontUseFBInk
. /mnt/us/ankio-tools/lib.sh
end() { say "$1"; exit 0; }
FLAG=/mnt/us/DISABLE_KOREADER_AUTOSTART
if [ -f "$FLAG" ]; then
	end "已是关闭状态。开机不会自动进入。未重启。"
fi
: > "$FLAG" || end "失败: 无法写入标志文件"
[ -f "$FLAG" ] || end "失败: 无法写入标志文件"
end "已关闭自启动。下次开机不会自动进入。未重启。未删除hook或worker。"
