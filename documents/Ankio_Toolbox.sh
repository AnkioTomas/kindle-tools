#!/bin/sh
# Name: Ankio工具箱
# Author: Ankio
# Icon: /mnt/us/ankio-tools/icons/ankio_toolbox.png
# DontUseFBInk
PATH=/bin:/sbin:/usr/bin:/usr/sbin
say() { printf '%s\n' "$1"; command -v eips >/dev/null 2>&1 && eips 1 22 "$1" >/dev/null 2>&1; sleep 4; }
end() { say "$1"; exit 0; }
BIN=/mnt/us/ankio-tools/kual-next/bin/kual-next
LAUNCH=/mnt/us/ankio-tools/kual-next/launch.sh
KR=/mnt/us/koreader/koreader.sh
PENDING=/var/tmp/ankio-pending-action

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

run_koreader() {
	[ -f "$KR" ] || end "fail: no koreader.sh"
	if is_koreader_running; then
		end "KOReader already running"
	fi
	# Official flags only: --kual or --kual --framework_stop
	# start after launch.sh has restored the framework (process wait, not sleep).
	cd /mnt/us/koreader || end "fail: cd koreader"
	exec /bin/sh "$KR" "$@"
}

[ -f "$BIN" ] || end "fail: no kual-next binary"
[ -f "$LAUNCH" ] || end "fail: no kual-next launch.sh"
[ -d /mnt/us/ankio-tools ] || end "fail: no ankio-tools menu"
# The prebuilt binary loads fonts from this fixed path.
FONT_DIR=/mnt/us/kual-next/fonts
for f in NotoSans.ttf NotoSansSymbols.ttf NotoSansSymbols2-Regular.otf; do
	[ -s "$FONT_DIR/$f" ] && continue
	mkdir -p "$FONT_DIR" && cp /mnt/us/ankio-tools/kual-next/fonts/"$f" "$FONT_DIR/$f" || end "fail: cannot install font $f"
done
rm -f "$PENDING"
export KUAL_NEXT_EXTENSIONS=/mnt/us/ankio-tools
/bin/sh "$LAUNCH"
st=$?
# Official launch.sh exits 125 when framework restoration is incomplete and skips handoff.
if [ "$st" = 125 ]; then
	rm -f "$PENDING"
	end "fail: framework not restored"
fi
token=
if [ -f "$PENDING" ]; then
	token=$(tr -cd 'a-z_' < "$PENDING")
	rm -f "$PENDING"
fi
case "$token" in
	koreader_normal) run_koreader --kual ;;
	koreader_nofw) run_koreader --kual --framework_stop ;;
	"" ) exit "$st" ;;
	*) exit "$st" ;;
esac
