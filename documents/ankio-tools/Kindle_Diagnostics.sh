#!/bin/sh
# Name: 故障检查
# Author: Ankio
# Icon: /mnt/us/documents/ankio-tools/icons/diagnostics.png
# DontUseFBInk
PATH=/bin:/sbin:/usr/bin:/usr/sbin
say() { printf '%s\n' "$1"; command -v eips >/dev/null 2>&1 && eips 1 22 "$1" >/dev/null 2>&1; sleep 4; }
end() { say "$1"; exit 0; }
DIR=/mnt/us/kindle-diagnostics
# Read-only diagnostics: write report only. Do not run other scripts, repair, or reboot.
# Do not print serial or MAC. Log snippets are historical and may not be the current fault.
mkdir -p "$DIR" || end "fail: cannot write report dir"
STAMP=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo unknown)
REP="$DIR/report-$STAMP.txt"
: > "$REP" || end "fail: cannot write report"

out() { printf '%s\n' "$*" >>"$REP"; }
sec() { out ""; out "==== $1 ===="; }
have() { command -v "$1" >/dev/null 2>&1; }
run() {
	if have "$1"; then
		"$@" >>"$REP" 2>&1 || out "failed: $*"
	else
		out "missing command: $1"
	fi
}

out "Ankio Kindle diagnostics"
out "time: $(date 2>/dev/null || echo unknown)"
out "NOTE: This report is read-only. Log excerpts are historical and may not be the current fault."
out "No other scripts were executed. No repair or reboot was attempted."

sec "firmware"
if [ -r /etc/prettyversion.txt ]; then
	cat /etc/prettyversion.txt >>"$REP" 2>&1 || out "cannot read prettyversion"
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

sec "scanner and gui status"
if have status; then
	status scanner >>"$REP" 2>&1 || out "status scanner: failed"
	status lab126_gui >>"$REP" 2>&1 || out "status lab126_gui: failed"
else
	out "missing command: status"
fi
if have pidof; then
	out "pidof scanner: $(pidof scanner 2>/dev/null || echo none)"
	out "pidof lab126_gui: $(pidof lab126_gui 2>/dev/null || echo none)"
else
	out "missing command: pidof"
fi

sec "fullScanStatus"
if have lipc-get-prop; then
	lipc-get-prop com.lab126.scanner fullScanStatus >>"$REP" 2>&1 || out "lipc-get-prop fullScanStatus: failed"
else
	out "missing command: lipc-get-prop"
fi

sec "appreg (read-only, shell-integration related)"
APPREG=
for p in /var/local/appreg.db /var/local/appreg/appreg.db; do
	[ -r "$p" ] && APPREG=$p && break
done
if [ -z "$APPREG" ]; then
	out "missing: appreg db"
elif have sqlite3; then
	out "db: $APPREG"
	sqlite3 "$APPREG" "SELECT handlerId, interface, contentId FROM associations WHERE handlerId LIKE '%shell_integration%' OR handlerId LIKE '%hackerdude%' OR contentId LIKE '%.sh%';" >>"$REP" 2>&1 || out "associations query failed"
	sqlite3 "$APPREG" "SELECT handlerId, name, value FROM properties WHERE handlerId LIKE '%shell_integration%' OR handlerId LIKE '%hackerdude%';" >>"$REP" 2>&1 || out "properties query failed"
else
	out "missing command: sqlite3 (db present at $APPREG, not queried)"
fi

sec "extractor paths (ls/readlink/hash)"
for p in /usr/lib/ccat/sh_integration_extractor.so /var/local/kmc/lib/sh_integration_extractor.so; do
	out "-- $p"
	if [ -e "$p" ] || [ -L "$p" ]; then
		ls -l "$p" >>"$REP" 2>&1 || out "ls failed: $p"
		if have readlink; then
			out "readlink: $(readlink "$p" 2>/dev/null || echo not-a-symlink-or-failed)"
		else
			out "missing command: readlink"
		fi
		if have md5sum; then
			md5sum "$p" >>"$REP" 2>&1 || out "md5sum failed: $p"
		elif have sha256sum; then
			sha256sum "$p" >>"$REP" 2>&1 || out "sha256sum failed: $p"
		else
			out "missing command: md5sum/sha256sum"
		fi
	else
		out "not found"
	fi
done

sec "rootfs mount"
if [ -r /proc/mounts ]; then
	awk '$2=="/" {print}' /proc/mounts >>"$REP" 2>&1 || out "cannot parse /proc/mounts"
else
	out "missing: /proc/mounts"
fi

sec "OTA binaries / backups / downloaded packages"
for p in /usr/bin/otaupd /usr/bin/otaupd.bck /usr/bin/otav3 /usr/bin/otav3.bck; do
	if [ -e "$p" ] || [ -L "$p" ]; then
		ls -l "$p" >>"$REP" 2>&1 || out "ls failed: $p"
	else
		out "not found: $p"
	fi
done
found_bin=0
# Only list update packages at userstore root; do not recurse or delete.
for p in /mnt/us/*.bin /mnt/us/*.BIN /mnt/us/update.bin /mnt/us/Update.bin; do
	[ -e "$p" ] || continue
	found_bin=1
	ls -l "$p" >>"$REP" 2>&1 || out "ls failed: $p"
done
[ "$found_bin" = 1 ] || out "no .bin update packages at /mnt/us root"

sec "KOReader autostart hook / flag / worker"
for p in /etc/upstart/koreader_autostart.conf /mnt/us/DISABLE_KOREADER_AUTOSTART /mnt/us/koreader/koreader_autostart_worker.sh /mnt/us/koreader/koreader.sh; do
	if [ -e "$p" ] || [ -L "$p" ]; then
		ls -l "$p" >>"$REP" 2>&1 || out "ls failed: $p"
	else
		out "not found: $p"
	fi
done
if [ -f /etc/upstart/koreader_autostart.conf ]; then
	if grep -q KOREADER_AUTOSTART_HOOK /etc/upstart/koreader_autostart.conf; then
		out "hook marker: KOREADER_AUTOSTART_HOOK present"
	else
		out "hook file exists but KOREADER_AUTOSTART_HOOK marker not found"
	fi
fi

sec "logs (max 80 lines; historical, may not be the current fault)"
out "Keywords: pathrejected, dlopen, libload, sh_integration, ccat, scanner, lab126_gui, koreader, otaupd, otav3"
TMPL="$DIR/.log-snip-$STAMP"
: >"$TMPL"
for f in /var/log/messages /var/log/syslog /var/log/messages.1; do
	[ -r "$f" ] || continue
	out "source file: $f"
	grep -E 'pathrejected|dlopen|libload|sh_integration|ccat|scanner|lab126_gui|koreader|otaupd|otav3' "$f" >>"$TMPL" 2>/dev/null || true
done
if have logread && [ ! -s "$TMPL" ]; then
	out "source: logread"
	logread 2>/dev/null | grep -E 'pathrejected|dlopen|libload|sh_integration|ccat|scanner|lab126_gui|koreader|otaupd|otav3' >>"$TMPL" || true
fi
if [ -s "$TMPL" ]; then
	# Keep the last 80 matching lines.
	if have tail; then
		tail -n 80 "$TMPL" >>"$REP" 2>&1
	else
		# fallback: print all if tail missing, but still cap with awk
		if have awk; then
			awk 'END{n=NR} {lines[NR]=$0} END{s=n-79; if(s<1)s=1; for(i=s;i<=n;i++) print lines[i]}' "$TMPL" >>"$REP"
		else
			out "missing command: tail/awk; log snippet omitted to avoid oversized dump"
		fi
	fi
else
	out "no matching log lines found (or no readable log source)"
fi
rm -f "$TMPL"

out ""
out "==== end ===="
out "report path: $REP"
printf '%s\n' "report: $REP"
end "diag saved, see USB report"
