#!/bin/sh
# Author: Ankio
# Read-only status/log report. Not a 4-second eips flash.
# Writes a readable file under /mnt/us/kindle-diagnostics.
# Also prints to stderr so KUAL Next appends it to the fixed /var/tmp/kual-next.log.
# Built-in "Save and reset KUAL log" can then copy that log to documents as a .txt book.
PATH=/bin:/sbin:/usr/bin:/usr/sbin
DIR=/mnt/us/kindle-diagnostics
STAMP=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)
mkdir -p "$DIR" 2>/dev/null || true
REP="$DIR/status-$STAMP.txt"
LATEST="$DIR/status-latest.txt"
TMP=$DIR/.status-tmp-$$
: >"$TMP" 2>/dev/null || TMP=/var/tmp/ankio-status-$$
: >"$TMP"

out() { printf '%s\n' "$*" >>"$TMP"; }
sec() { out ""; out "==== $1 ===="; }
have() { command -v "$1" >/dev/null 2>&1; }

is_koreader_running() {
	for d in /proc/[0-9]*; do
		[ -r "$d/cmdline" ] || continue
		cmd=$(tr '\0' ' ' < "$d/cmdline" 2>/dev/null)
		case "$cmd" in
			*luajit*reader.lua*|*koreader/reader.lua*) return 0 ;;
		esac
	done
	return 1
}

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

out "Ankio status and logs"
out "time: $(date 2>/dev/null || echo unknown)"
out "This file is the status report. It is also appended to /var/tmp/kual-next.log."
out "To read the KUAL log as a book: in the toolbox KUAL menu, choose Save and reset KUAL log,"
out "then open the new KUAL-*.txt file in the Kindle library."
out "MTP copy: $LATEST"

sec "firmware"
if [ -r /etc/prettyversion.txt ]; then
	cat /etc/prettyversion.txt >>"$TMP" 2>/dev/null || out "cannot read prettyversion"
else
	out "missing: /etc/prettyversion.txt"
fi
if [ -r /proc/cmdline ]; then
	if grep -q androidboot.veritymode /proc/cmdline; then
		out "verity: $(grep -o 'androidboot.veritymode=[^ ]*' /proc/cmdline)"
	else
		out "verity: not present in cmdline"
	fi
else
	out "missing: /proc/cmdline"
fi

sec "gui and scanner"
if have status; then
	status lab126_gui >>"$TMP" 2>/dev/null || out "status lab126_gui: failed"
	status scanner >>"$TMP" 2>/dev/null || out "status scanner: failed"
else
	out "missing command: status"
fi
if is_koreader_running; then
	out "KOReader process: running"
else
	out "KOReader process: not running"
fi

sec "KOReader autostart (flag / hook / worker / process)"
if [ -f /etc/upstart/koreader_autostart.conf ]; then
	out "hook: present /etc/upstart/koreader_autostart.conf"
	if grep -q KOREADER_AUTOSTART_HOOK /etc/upstart/koreader_autostart.conf; then
		out "hook marker: KOREADER_AUTOSTART_HOOK present"
	else
		out "hook marker: KOREADER_AUTOSTART_HOOK not found"
	fi
else
	out "hook: not found"
fi
if [ -f /mnt/us/DISABLE_KOREADER_AUTOSTART ]; then
	out "disable flag: present (autostart will skip)"
else
	out "disable flag: absent"
fi
if [ -f /mnt/us/koreader/koreader_autostart_worker.sh ]; then
	out "worker: present /mnt/us/koreader/koreader_autostart_worker.sh"
else
	out "worker: not found"
fi
if [ -f /mnt/us/koreader/koreader.sh ]; then
	out "koreader.sh: present"
else
	out "koreader.sh: not found"
fi

sec "Telnet listener (this tool only)"
found=0
for f in /var/run/ankio_telnet.pid /tmp/ankio_telnet.pid; do
	if [ -f "$f" ]; then
		pid=$(tr -cd '0-9' < "$f")
		if is_telnetd "$pid"; then
			out "pidfile $f: telnetd pid $pid (cmdline verified)"
			found=1
		else
			out "pidfile $f: stale or not telnetd"
		fi
	fi
done
[ "$found" = 1 ] || out "no verified telnetd from this tool's pidfile"
if [ -f /var/run/ankio_telnet.fw ] || [ -f /tmp/ankio_telnet.fw ]; then
	out "firewall mark file: present"
else
	out "firewall mark file: absent"
fi

sec "OTA rename status"
for b in /usr/bin/otaupd /usr/bin/otav3; do
	if [ -f "$b" ] && [ -f "$b.bck" ]; then
		out "$b: live and backup both present (conflict)"
	elif [ -f "$b.bck" ]; then
		out "$b: renamed to $b.bck (disabled)"
	elif [ -f "$b" ]; then
		out "$b: present (enabled/live)"
	else
		out "$b: not found (no live, no backup)"
	fi
done

sec "recent diagnostics reports"
set --
for f in "$DIR"/report-*.txt "$DIR"/status-*.txt; do
	[ -f "$f" ] || continue
	set -- "$@" "$f"
done
if [ "$#" -eq 0 ]; then
	out "no previous report/status files"
elif have ls; then
	n=0
	ls -t "$@" 2>/dev/null | {
		while IFS= read -r f; do
			[ -f "$f" ] || continue
			n=$((n + 1))
			[ "$n" -le 5 ] || break
			ls -l "$f" >>"$TMP" 2>/dev/null || out "$f"
		done
	}
else
	# no ls: list up to 5 existing paths unsorted
	n=0
	for f in "$@"; do
		n=$((n + 1))
		[ "$n" -le 5 ] || break
		out "$f"
	done
fi

sec "recent kual-next.log (last 80 lines)"
LOG=/var/tmp/kual-next.log
if [ -r "$LOG" ]; then
	out "source: $LOG"
	if have tail; then
		tail -n 80 "$LOG" >>"$TMP" 2>/dev/null || out "tail failed"
	elif have awk; then
		awk 'END{n=NR} {lines[NR]=$0} END{s=n-79; if(s<1)s=1; for(i=s;i<=n;i++) print lines[i]}' "$LOG" >>"$TMP"
	else
		out "missing command: tail/awk; log not dumped"
	fi
else
	out "not found or unreadable: $LOG"
fi

out ""
out "==== end ===="
out "report path: $LATEST"

# Publish readable copies. Also copy to stderr for the fixed KUAL log.
if [ -s "$TMP" ]; then
	if [ -d "$DIR" ]; then
		cp "$TMP" "$REP" 2>/dev/null || true
		cp "$TMP" "$LATEST" 2>/dev/null || true
	fi
	cat "$TMP" >&2
fi
rm -f "$TMP"
. /mnt/us/ankio-tools/lib.sh
say "状态报告已保存: $LATEST"
exit 0
