#!/bin/sh
# Author: Ankio
# KOReader one-shot boot worker (no framework). Not a library scriptlet.
# Invoked by /etc/upstart/koreader_autostart.conf
FLAG=/mnt/us/DISABLE_KOREADER_AUTOSTART
KR=/mnt/us/koreader/koreader.sh
[ -f "$FLAG" ] && exit 0
[ -r /proc/sys/kernel/random/boot_id ] || exit 0
BOOT_ID=$(tr -cd '0-9a-fA-F-' < /proc/sys/kernel/random/boot_id)
[ -n "$BOOT_ID" ] || exit 0
LOCK=/var/tmp/koreader_autostart.$BOOT_ID.lock
mkdir "$LOCK" 2>/dev/null || exit 0

wait_ready() {
	n=0
	stable=0
	ok=0
	while [ "$n" -lt 45 ]; do
		[ -f "$FLAG" ] && return 1
		ready=0
		avail=$(lipc-get-prop com.lab126.volumd userstoreIsAvailable 2>/dev/null)
		dm=$(lipc-get-prop com.lab126.volumd driveModeState 2>/dev/null)
		gui=0
		if command -v status >/dev/null 2>&1 && status lab126_gui 2>/dev/null | grep -q running; then
			gui=1
		fi
		if [ "$avail" = "1" ] && [ "$gui" = "1" ] && [ -f "$KR" ] && [ -r "$KR" ]; then
			if [ -z "$dm" ] || [ "$dm" = "0" ]; then
				ready=1
			fi
		fi
		if [ "$ready" = "1" ]; then
			stable=$((stable + 1))
			if [ "$stable" -ge 3 ]; then
				ok=1
				break
			fi
		else
			stable=0
		fi
		sleep 2
		n=$((n + 1))
	done
	[ "$ok" = "1" ] || return 1
	[ -f "$FLAG" ] && return 1
	return 0
}

restore_gui() {
	command -v start >/dev/null 2>&1 || return 0
	if command -v status >/dev/null 2>&1 && status lab126_gui 2>/dev/null | grep -q running; then
		return 0
	fi
	start lab126_gui >/dev/null 2>&1 || true
}

wait_ready || exit 0
[ -f "$FLAG" ] && exit 0

trap restore_gui EXIT
trap 'restore_gui; exit 0' INT TERM HUP
/bin/sh "$KR" --kual --framework_stop
exit 0
