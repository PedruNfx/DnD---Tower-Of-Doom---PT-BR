<?php
// For a sprite block at (X,Y) of W x H 16x16 cells, list the tiles in [lo,hi) that fit each cell (many-to-one, pen 15 ignored).
[$_, $gf, $sf, $X, $Y, $W, $H, $lo, $hi] = $argv; $g = file_get_contents($gf); $im = imagecreatefrompng($sf); $lo = hexdec($lo); $hi = hexdec($hi);
$tiles = [];
for ($t = $lo; $t < $hi; $t++) { $px = []; for ($y = 0; $y < 16; $y++) { $b = unpack('C8', substr($g, $t * 128 + $y * 8, 8));
    for ($x = 0; $x < 16; $x++) { $q = $x < 8 ? 0 : 4; $bit = 7 - ($x % 8);
      $px[] = ((($b[$q + 4] >> $bit) & 1) << 3) | ((($b[$q + 3] >> $bit) & 1) << 2) | ((($b[$q + 2] >> $bit) & 1) << 1) | (($b[$q + 1] >> $bit) & 1); } }
  $op = 0; foreach ($px as $p) if ($p != 15) $op++; if ($op >= 30) $tiles[$t] = [$px, $op]; }
for ($r = 0; $r < $H; $r++) { $row = [];
  for ($c = 0; $c < $W; $c++) { $sx = $X + 16 * $c; $sy = $Y + 16 * $r; $best = [];
    foreach ($tiles as $t => [$px, $op]) { $m = []; $ok = true;
      for ($i = 0; $i < 256; $i++) { $p = $px[$i]; if ($p == 15) continue; $cc = @imagecolorat($im, $sx + ($i & 15), $sy + ($i >> 4)); if (isset($m[$p])) { if ($m[$p] !== $cc) { $ok = false; break; } } else $m[$p] = $cc; }
      if ($ok && count(array_unique($m)) >= 2) $best[$t] = $op; }
    arsort($best); $row[] = $best ? implode('/', array_map(fn($t) => sprintf('%04X', $t), array_slice(array_keys($best), 0, 3))) : '----'; }
  echo "row $r: " . implode('  ', $row) . "\n"; }
