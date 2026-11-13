#!/bin/sh
# Author: Ankio
# exitmenu helper: record a whitelist token only. Do not start KOReader here.
# KUAL Next exec_and_exit restores its framework, then execs this script.
# launch.sh then waits for us, restores again, and returns to Ankio_Toolbox.sh.
PENDING=/var/tmp/ankio-pending-action
rm -f "$PENDING"
case "$1" in
	normal) token=koreader_normal ;;
	nofw) token=koreader_nofw ;;
	*) exit 0 ;;
esac
printf '%s\n' "$token" > "$PENDING" || rm -f "$PENDING"
exit 0
