# Shared result feedback. eips cannot draw Chinese, so the screen shows
# an English summary; the full Chinese text goes to stdout and last-result.txt.
RESULT_FILE=/mnt/us/ankio-tools/last-result.txt

en_text() {
	case "$1" in
		*chattr*) echo "chattr failed, nothing changed" ;;
		*mntroot*rw*) echo "Cannot remount system read-write, nothing changed" ;;
		*verity*) echo "Rootless/verity device, not supported" ;;
		*upstart*) echo "Failed to write upstart job" ;;
		*已有未知同名*) echo "Unknown upstart job exists, nothing changed" ;;
		*冲突*) echo "Conflicting update binaries, nothing changed" ;;
		*改名*|*恢复\ *) echo "Rename failed" ;;
		*无mntroot*) echo "mntroot not found, nothing changed" ;;
		*worker*) echo "Autostart worker problem, nothing changed" ;;
		*标志文件*) echo "Cannot write flag file" ;;
		*koreader.sh*) echo "koreader.sh not found, nothing changed" ;;
		*otaupd*) echo "OTA binaries not found, nothing changed" ;;
		*符号链接*|*非普通文件*) echo "Unexpected file type, nothing changed" ;;
		*已清理锁屏广告*) echo "Lockscreen ads cleaned and blocked. Reboot to apply" ;;
		*已取消广告拦截*) echo "Ad blocking removed. Reboot to apply" ;;
		*已是未拦截状态*) echo "Ads were not blocked, nothing changed" ;;
		*已是清理状态*) echo "Ads were already cleaned" ;;
		*广告*) echo "Ad cleanup failed, nothing changed" ;;
		*已关闭自启动*) echo "KOReader autostart disabled" ;;
		*已安装自启动*) echo "KOReader autostart installed. Reboot to apply" ;;
		*已恢复自动更新*) echo "Auto update restored. Reboot to apply" ;;
		*已是关闭状态*) echo "Autostart was already disabled" ;;
		*已是恢复状态*) echo "Auto update was already enabled" ;;
		*已是禁用状态*) echo "Auto update was already disabled" ;;
		*已禁用自动更新*) echo "Auto update disabled. Reboot to apply" ;;
		*状态报告已保存*) echo "Status report saved to /mnt/us/kindle-diagnostics/status-latest.txt" ;;
		"diag saved"*) echo "Diagnostics saved to /mnt/us/kindle-diagnostics" ;;
		"already running"*) echo "Telnet already running, stop it first" ;;
		"telnet started"*) echo "Telnet started on port 23" ;;
		"stopped;"*) echo "Telnet stopped (open sessions may remain)" ;;
		"stale pid"*) echo "Stale telnet pid cleared" ;;
		"no pid"*) echo "Telnet was not started by this tool" ;;
		fail:*|失败*) echo "${1#fail: }" ;;
		*) echo "$1" ;;
	esac
}

say() {
	case "$1" in
		fail*|失败*|错误*) tag="FAILED" ;;
		*) tag="DONE" ;;
	esac
	en=$(en_text "$1")
	printf '[%s] %s\n' "$tag" "$1"
	printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)" "$tag" "$1" > "$RESULT_FILE" 2>/dev/null
	if command -v eips >/dev/null 2>&1; then
		eips 0 19 "                                        " >/dev/null 2>&1
		eips 0 20 "========================================" >/dev/null 2>&1
		eips 0 21 "  [ $tag ]                              " >/dev/null 2>&1
		row=22
		printf '%s\n' "$en" | fold -s -w 38 | while IFS= read -r line; do
			eips 0 "$row" "  $line                              " >/dev/null 2>&1
			row=$((row + 1))
		done
		eips 0 25 "========================================" >/dev/null 2>&1
	fi
	sleep 6
	if command -v eips >/dev/null 2>&1; then
		for r in 19 20 21 22 23 24 25; do eips 0 "$r" "                                        " >/dev/null 2>&1; done
	fi
}
