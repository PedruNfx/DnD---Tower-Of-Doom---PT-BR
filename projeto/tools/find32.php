<?php
// Search 32x32 (scroll3-format) tiles: each 8x8 sub-block vs a screenshot cell (many-to-one pen->colour).
// usage: php find32.php gfx shot X Y   (cell top-left on screen)
[$_, $gf, $sf, $sx, $sy] = $argv; $g = file_get_contents($gf); $im = imagecreatefrompng($sf); $n = intdiv(strlen($g), 512);
$scr = []; for ($i = 0; $i < 64; $i++) $scr[$i] = imagecolorat($im, $sx + ($i & 7), $sy + ($i >> 3));
for ($t = 0; $t < $n; $t++) { $B = $t * 512;
  for ($by = 0; $by < 4; $by++) for ($bx = 0; $bx < 4; $bx++) { $m = []; $ok = true;
    for ($y = 0; $y < 8 && $ok; $y++) { $b = unpack('C4', substr($g, $B + ($by * 8 + $y) * 16 + 4 * $bx, 4));
      for ($x = 0; $x < 8; $x++) { $bit = 7 - $x; $p = ((($b[4] >> $bit) & 1) << 3) | ((($b[3] >> $bit) & 1) << 2) | ((($b[2] >> $bit) & 1) << 1) | (($b[1] >> $bit) & 1);
        $c = $scr[$y * 8 + $x]; if (isset($m[$p])) { if ($m[$p] !== $c) { $ok = false; break; } } else $m[$p] = $c; } }
    if ($ok && count($m) >= 3) printf("tile32 %05X (byte %06X) sub(%d,%d)\n", $t, $B, $bx, $by); } }
