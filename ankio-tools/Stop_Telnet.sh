#!/bin/sh
# Name: 关闭Telnet
# Author: Ankio
# Icon: /mnt/us/ankio-tools/icons/stop_telnet.png
# DontUseFBInk
PATH=/bin:/sbin:/usr/bin:/usr/sbin
CHAIN=ANKIO_TELNET
MARK=ANKIO_TELNET_OWN
. /mnt/us/ankio-tools/lib.sh
end() { say "$1"; exit 0; }
[ "$(id -u 2>/dev/null)" = 0 ] || end "fail: need root"
is_telnetd() {
	pid=$1
	case "$pid" in ''|*[!0-9]*) return 1 ;; esac
	[ -r "/proc/$pid/cmdline" ] || return 1
	cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
	set -- $cmd
	[ -n "$1" ] || return 1
	case "$1" in
		telnetd|*/telnetd) return 0 ;;
		busybox|*/busybox) [ "$2" = "telnetd" ]; return $? ;;
		*) return 1 ;;
	esac
}
fw_has_mark() {
	iptables -t filter -S 2>/dev/null | grep -q "$MARK" && return 0
	[ -f /var/run/ankio_telnet.fw ] || [ -f /tmp/ankio_telnet.fw ]
}
status=none
for f in /var/run/ankio_telnet.pid /tmp/ankio_telnet.pid; do
	[ -f "$f" ] || continue
	pid=$(tr -cd '0-9' < "$f")
	if is_telnetd "$pid"; then
		if kill "$pid" 2>/dev/null; then
			status=killed
		else
			[ "$status" = killed ] || status=failkill
		fi
	else
		[ "$status" = killed ] || [ "$status" = failkill ] || status=stale
	fi
	rm -f "$f"
done
if fw_has_mark; then
	iptables -t filter -D INPUT -p tcp --dport 23 -m comment --comment "$MARK" -j "$CHAIN" 2>/dev/null || \
		iptables -t filter -D INPUT -p tcp --dport 23 -j "$CHAIN" 2>/dev/null || true
	iptables -t filter -D "$CHAIN" -p tcp --dport 23 -m comment --comment "$MARK" -j ACCEPT 2>/dev/null || \
		iptables -t filter -D "$CHAIN" -p tcp --dport 23 -j ACCEPT 2>/dev/null || true
	# Do not -F the table or chain; only delete this tool's rules, then -X if empty.
	iptables -t filter -S "$CHAIN" 2>/dev/null | grep -q '^-A ' || iptables -t filter -X "$CHAIN" 2>/dev/null || true
	rm -f /var/run/ankio_telnet.fw /tmp/ankio_telnet.fw
fi
case "$status" in
	killed) end "stopped; sessions may remain" ;;
	failkill) end "fail: kill" ;;
	stale) end "stale pid, cleared" ;;
	*) end "no pid from this tool" ;;
esac
