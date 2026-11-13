#!/bin/sh
# Name: 开启Telnet
# Author: Ankio
# Icon: /mnt/us/ankio-tools/icons/start_telnet.png
# DontUseFBInk
PATH=/bin:/sbin:/usr/bin:/usr/sbin
CHAIN=ANKIO_TELNET
MARK=ANKIO_TELNET_OWN
say() { printf '%s\n' "$1"; command -v eips >/dev/null 2>&1 && eips 1 22 "$1" >/dev/null 2>&1; sleep 4; }
end() { say "$1"; exit 0; }
[ "$(id -u 2>/dev/null)" = 0 ] || end "fail: need root"
command -v telnetd >/dev/null 2>&1 || end "fail: no telnetd"
command -v iptables >/dev/null 2>&1 || end "fail: no iptables"
is_telnetd() {
	case "$1" in ''|*[!0-9]*) return 1 ;; esac
	[ -r "/proc/$1/cmdline" ] || return 1
	set -- $(tr '\0' ' ' < "/proc/$1/cmdline" 2>/dev/null)
	case "$1" in
		telnetd|*/telnetd) return 0 ;;
		busybox|*/busybox) [ "$2" = "telnetd" ]; return $? ;;
		*) return 1 ;;
	esac
}
fw_mark_file() {
	if [ -d /var/run ] && [ -w /var/run ]; then
		printf '%s\n' "$MARK" > /var/run/ankio_telnet.fw
	else
		printf '%s\n' "$MARK" > /tmp/ankio_telnet.fw
	fi
}
fw_has_mark() {
	iptables -t filter -S 2>/dev/null | grep -q "$MARK" && return 0
	[ -f /var/run/ankio_telnet.fw ] || [ -f /tmp/ankio_telnet.fw ]
}
fw_off() {
	fw_has_mark || return 0
	iptables -t filter -D INPUT -p tcp --dport 23 -m comment --comment "$MARK" -j "$CHAIN" 2>/dev/null || \
		iptables -t filter -D INPUT -p tcp --dport 23 -j "$CHAIN" 2>/dev/null || true
	iptables -t filter -D "$CHAIN" -p tcp --dport 23 -m comment --comment "$MARK" -j ACCEPT 2>/dev/null || \
		iptables -t filter -D "$CHAIN" -p tcp --dport 23 -j ACCEPT 2>/dev/null || true
	# Never iptables -F the table or this chain (others may share the chain).
	iptables -t filter -S "$CHAIN" 2>/dev/null | grep -q '^-A ' || iptables -t filter -X "$CHAIN" 2>/dev/null || true
	rm -f /var/run/ankio_telnet.fw /tmp/ankio_telnet.fw
}
live=
for f in /var/run/ankio_telnet.pid /tmp/ankio_telnet.pid; do
	[ -f "$f" ] || continue
	is_telnetd "$(tr -cd '0-9' < "$f")" && live=1 || rm -f "$f"
done
[ -n "$live" ] && end "already running, stop first"
for d in /proc/[0-9]*; do is_telnetd "${d#/proc/}" && end "already running, stop first"; done
iptables -t filter -S INPUT >/dev/null 2>&1 || end "fail: iptables"
iptables -t filter -L "$CHAIN" -n >/dev/null 2>&1 || iptables -t filter -N "$CHAIN" || end "fail: firewall"
iptables -t filter -L "$CHAIN" -n >/dev/null 2>&1 || end "fail: firewall"
if ! iptables -t filter -S INPUT 2>/dev/null | grep -q -- "-j $CHAIN"; then
	iptables -t filter -I INPUT -p tcp --dport 23 -m comment --comment "$MARK" -j "$CHAIN" 2>/dev/null || \
		iptables -t filter -I INPUT -p tcp --dport 23 -j "$CHAIN" || end "fail: firewall"
fi
if ! iptables -t filter -S "$CHAIN" 2>/dev/null | grep -q -- "--dport 23 -j ACCEPT"; then
	iptables -t filter -A "$CHAIN" -p tcp --dport 23 -m comment --comment "$MARK" -j ACCEPT 2>/dev/null || \
		iptables -t filter -A "$CHAIN" -p tcp --dport 23 -j ACCEPT || { fw_off; end "fail: firewall"; }
fi
fw_mark_file
telnetd -l /bin/sh -p 23 || { fw_off; end "fail: start telnetd"; }
sleep 1
pid=
for d in /proc/[0-9]*; do is_telnetd "${d#/proc/}" && { pid=${d#/proc/}; break; }; done
[ -n "$pid" ] || { fw_off; end "fail: start telnetd"; }
PF=/tmp/ankio_telnet.pid
[ -d /var/run ] && [ -w /var/run ] && PF=/var/run/ankio_telnet.pid
printf '%s\n' "$pid" > "$PF" || { kill "$pid" 2>/dev/null || true; fw_off; end "fail: pidfile"; }
printf 'IPs:\n'
command -v ip >/dev/null 2>&1 && ip -4 -o addr show 2>/dev/null || ifconfig 2>/dev/null
end "telnet started :23"
