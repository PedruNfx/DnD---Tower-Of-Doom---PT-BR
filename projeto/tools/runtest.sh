#!/bin/bash
# usage: runtest.sh <outdir|-> <ff_ms> <shots> <interval_ms> <sheetprefix> [statefile-slot]
# Installs <outdir> ROM files as the FBNeo patched romset (or none with "-"), boots RetroArch,
# fast-forwards for ff_ms (real time), then takes screenshots and builds contact sheets.
S="/c/Users/Admin/AppData/Local/Temp/claude/C--Users-Admin-Documents-youtube-cast-firefox/3181a183-bc25-48df-804b-b0d27904f57c/scratchpad"
OUT="$1"; FF="$2"; N="$3"; IV="$4"; PFX="$5"
W=$(cygpath -w "$S")
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$S/tools/killtest.ps1")" >/dev/null 2>&1
PZ="$S/test/system/fbneo/patched/ddtodur1.zip"
rm -f "$PZ"
if [ "$OUT" != "-" ]; then
  LIST=""; for f in dadu.03a dadu.04a dadu.05a dad.06 dad.07 dad.13m dad.15m dad.17m dad.19m dad.14m dad.16m dad.18m dad.20m; do cmp -s "$OUT/$f" "$S/rom/$f" || LIST="$LIST,'$(cygpath -w "$OUT/$f")'"; done
  powershell.exe -NoProfile -Command "Compress-Archive -Path ${LIST#,} -DestinationPath '$(cygpath -w "$PZ")'" || exit 1
fi
rm -f "$S/test/shots/"*.png
powershell.exe -NoProfile -Command "Start-Process -FilePath 'C:\\RetroArch-Win64\\retroarch.exe' -ArgumentList '-c','\"$W\\test\\base.cfg\"','--appendconfig','\"$W\\test\\over.cfg\"','-L','C:\\RetroArch-Win64\\cores\\fbneo_libretro.dll','\"$W\\test\\roms\\ddtodur1.zip\"','--verbose','--log-file','\"$W\\test\\ra.log\"'"
perl "$S/tools/ra.pl" wait 3500
grep -q 'Driver successfully started' "$S/test/ra.log" || { echo "core did not start"; grep -i -E 'error|required' "$S/test/ra.log" | head; exit 1; }
if [ "$FF" -gt 0 ]; then perl "$S/tools/ra.pl" cmd FAST_FORWARD wait "$FF" cmd FAST_FORWARD; fi
for i in $(seq 1 "$N"); do perl "$S/tools/ra.pl" cmd SCREENSHOT wait "$IV"; done
cd "$S/test/shots" || exit 1
ls *.png > ../list.txt
total=$(wc -l < ../list.txt); per=20; k=0
for start in $(seq 1 $per "$total"); do k=$((k+1)); php "$S/tools/sheet.php" "$S/${PFX}_$k.png" 4 $(sed -n "${start},$((start+per-1))p" ../list.txt); done
echo "shots=$total sheets=$k"
