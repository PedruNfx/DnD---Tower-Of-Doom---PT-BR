<?php
// 32x32 tile matcher (tile t: 512 bytes, row y at t*512+y*16, 8-px group g at +4g): match32.php gfx shot lo hi colour minhits x,y...
$a = $argv; $g = file_get_contents($a[1]); $im = imagecreatefrompng($a[2]); $lo = hexdec($a[3]); $hi = hexdec($a[4]); $col = hexdec($a[5]); $minp = (int)$a[6];
$pos = array_map(fn($s) => array_map('intval', explode(',', $s)), array_slice($a, 7)); $W = imagesx($im); $H = imagesy($im);
for ($t = $lo; $t < $hi; $t++) { $base = $t * 512; if ($base + 512 > strlen($g)) break; $px = [];
  for ($y = 0; $y < 32; $y++) for ($gr = 0; $gr < 4; $gr++) { $b = unpack('C4', substr($g, $base + $y * 16 + $gr * 4, 4));
    for ($x = 0; $x < 8; $x++) { $bit = 7 - $x; $px[$y * 32 + $gr * 8 + $x] = ((($b[4] >> $bit) & 1) << 3) | ((($b[3] >> $bit) & 1) << 2) | ((($b[2] >> $bit) & 1) << 1) | (($b[1] >> $bit) & 1); } }
  foreach ($pos as [$sx, $sy]) { $m = []; $ok = true; $hit = 0;
    for ($i = 0; $i < 1024; $i++) { $p = $px[$i]; if ($p == 15) continue; $X = $sx + ($i & 31); $Y = $sy + ($i >> 5); if ($X >= $W || $Y >= $H) continue;
      $c = imagecolorat($im, $X, $Y); if (isset($m[$p])) { if ($m[$p] !== $c) { $ok = false; break; } } else $m[$p] = $c; if ($c == $col) $hit++; }
    if ($ok && $hit >= $minp) printf("tile %04X at (%d,%d) hits %d\n", $t, $sx, $sy, $hit); } }
