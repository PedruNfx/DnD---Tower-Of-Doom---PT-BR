<?php
// Find 8x8 scroll1 half-tiles (unit 0x20000+c, half 0/1) that fit given screen cells (many-to-one, pen 15 ignored).
// usage: php s1find.php gfx shot lo_hex hi_hex x,y [x,y ...]
$g = file_get_contents($argv[1]); $im = imagecreatefrompng($argv[2]); $lo = hexdec($argv[3]); $hi = hexdec($argv[4]);
$cells = array_slice($argv, 5); $scr = [];
foreach ($cells as $k => $xy) { [$x0, $y0] = explode(',', $xy); for ($i = 0; $i < 64; $i++) $scr[$k][$i] = imagecolorat($im, $x0 + ($i & 7), $y0 + ($i >> 3)); }
for ($u = $lo; $u < $hi; $u++) { $base = ($u + 0x20000) * 64;
  for ($h = 0; $h < 2; $h++) { $px = [];
    for ($y = 0; $y < 8; $y++) { $b = unpack('C4', substr($g, $base + $y * 8 + 4 * $h, 4));
      for ($x = 0; $x < 8; $x++) { $bit = 7 - $x; $px[] = ((($b[4] >> $bit) & 1) << 3) | ((($b[3] >> $bit) & 1) << 2) | ((($b[2] >> $bit) & 1) << 1) | (($b[1] >> $bit) & 1); } }
    $op = 0; foreach ($px as $p) if ($p != 15) $op++; if ($op < 12) continue;
    foreach ($scr as $k => $s) { $m = []; $ok = true;
      for ($i = 0; $i < 64; $i++) { $p = $px[$i]; if ($p == 15) continue; if (isset($m[$p])) { if ($m[$p] !== $s[$i]) { $ok = false; break; } } else $m[$p] = $s[$i]; }
      if ($ok && count(array_unique($m)) >= 2 && in_array(0x44AAFF, $m)) printf("cell %s: code %04X half %d (opaque %d)\n", $cells[$k], $u, $h, $op); } } }
