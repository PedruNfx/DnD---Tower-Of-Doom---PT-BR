<?php
// sprite/scroll2 16x16 matcher requiring >= N pixels that land on a given colour: match16w.php gfx shot x0 y0 x1 y1 lo hi colour_hex minpix
[$_, $gf, $sf, $x0, $y0, $x1, $y1, $lo, $hi, $col, $minp] = $argv; $g = file_get_contents($gf); $im = imagecreatefrompng($sf); $lo = hexdec($lo); $hi = hexdec($hi); $col = hexdec($col);
$S = []; for ($y = $y0; $y <= $y1 + 16; $y++) for ($x = $x0; $x <= $x1 + 16; $x++) $S[$y][$x] = @imagecolorat($im, $x, $y);
for ($t = $lo; $t < $hi; $t++) { $px = [];
  for ($y = 0; $y < 16; $y++) { $b = unpack('C8', substr($g, $t * 128 + $y * 8, 8)); if (!$b) continue 2;
    for ($x = 0; $x < 16; $x++) { $q = $x < 8 ? 0 : 4; $bit = 7 - ($x % 8);
      $px[] = ((($b[$q + 4] >> $bit) & 1) << 3) | ((($b[$q + 3] >> $bit) & 1) << 2) | ((($b[$q + 2] >> $bit) & 1) << 1) | (($b[$q + 1] >> $bit) & 1); } }
  $op = 0; foreach ($px as $p) if ($p != 15) $op++; if ($op < $minp) continue;
  for ($sy = $y0; $sy <= $y1; $sy++) for ($sx = $x0; $sx <= $x1; $sx++) { $m = []; $ok = true; $hit = 0;
    for ($i = 0; $i < 256; $i++) { $p = $px[$i]; if ($p == 15) continue; $c = $S[$sy + ($i >> 4)][$sx + ($i & 15)];
      if (isset($m[$p])) { if ($m[$p] !== $c) { $ok = false; break; } } else $m[$p] = $c; if ($c == $col) $hit++; }
    if ($ok && $hit >= $minp && count(array_unique($m)) >= 2) printf("tile %04X at (%d,%d) hits %d\n", $t, $sx, $sy, $hit); } }
