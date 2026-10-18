#!/bin/bash
# usage: filltest.sh RANGES outpng  -> build with FILL, boot, coin+start, screenshot select screen,
# report how many of the CLERIC box text pixels (white in the reference shot) changed
S="/c/Users/Admin/AppData/Local/Temp/claude/C--Users-Admin-Documents-youtube-cast-firefox/3181a183-bc25-48df-804b-b0d27904f57c/scratchpad"
rm -rf "$S/out_dbg"; FILL="$1" T="$S/tools" perl "$S/tools/build.pl" "$S/rom" "$S/tr" "$S/out_dbg" >/dev/null 2>&1
bash "$S/tools/runtest.sh" "$S/out_dbg" 0 0 1000 none >/dev/null 2>&1; perl "$S/tools/ra.pl" wait 12000; rm -f "$S/test/shots/"*.png
perl -e 'require "$ARGV[0]"; Pad::hold(0.3,"SELECT"); Pad::idle(1.0); Pad::hold(0.2,"START"); Pad::idle(1.8); Pad::cmd("SCREENSHOT"); Pad::idle(0.5);' "$S/tools/pad.pl"
f=$(ls "$S/test/shots" | head -1); cp "$S/test/shots/$f" "$2"
php -r '$a=imagecreatefrompng($argv[1]); $b=imagecreatefrompng($argv[2]); $d=0; $t=0;
  for($y=70;$y<90;$y++) for($x=288;$x<368;$x++) { $cb=imagecolorat($b,$x,$y); if($cb==0xFFFFFF){ $t++; if(imagecolorat($a,$x,$y)!=$cb) $d++; } }
  echo "text pixels changed: $d of $t\n";' "$(cygpath -m "$2")" "$(cygpath -m "$S/sel4.png")"
