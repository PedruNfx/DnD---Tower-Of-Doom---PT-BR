<?php
// Find where 16x16 sprite tiles fit on a screenshot (many-to-one pen->colour, transparent pen 15 ignored).
// usage: php match16.php gfx shot x0 y0 x1 y1 tile_lo_hex tile_hi_hex
[$_, $gf, $sf, $x0, $y0, $x1, $y1, $lo, $hi] = $argv; $g = file_get_contents($gf); $im = imagecreatefrompng($sf); $lo = hexdec($lo); $hi = hexdec($hi);
$S = []; for ($y = $y0; $y <= $y1 + 16; $y++) for ($x = $x0; $x <= $x1 + 16; $x++) $S[$y][$x] = @imagecolorat($im, $x, $y);
for ($t = $lo; $t < $hi; $t++) { $px = [];
  for ($y = 0; $y < 16; $y++) { $b = unpack('C8', substr($g, $t * 128 + $y * 8, 8));
    for ($x = 0; $x < 16; $x++) { $q = $x < 8 ? 0 : 4; $bit = 7 - ($x % 8);
      $px[] = ((($b[$q + 4] >> $bit) & 1) << 3) | ((($b[$q + 3] >> $bit) & 1) << 2) | ((($b[$q + 2] >> $bit) & 1) << 1) | (($b[$q + 1] >> $bit) & 1); } }
  $opaque = 0; $pens = []; foreach ($px as $p) if ($p != 15) { $opaque++; $pens[$p] = 1; } if ($opaque < 40 || count($pens) < 2) continue;
  for ($sy = $y0; $sy <= $y1; $sy++) for ($sx = $x0; $sx <= $x1; $sx++) { $m = []; $ok = true;
    for ($i = 0; $i < 256; $i++) { $p = $px[$i]; if ($p == 15) continue; $c = $S[$sy + ($i >> 4)][$sx + ($i & 15)];
      if (isset($m[$p])) { if ($m[$p] !== $c) { $ok = false; break; } } else $m[$p] = $c; }
    if ($ok && in_array(0xBBBBBB, $m) && in_array(0x000099, $m)) printf("tile %04X at (%d,%d)\n", $t, $sx, $sy); } }
