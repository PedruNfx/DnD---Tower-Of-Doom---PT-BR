<?php
// For a screen box, find the 8x8 grid alignment with the most uniquely-matching tiles; print the code grid.
// usage: php boxgrid.php gfx shot X0 Y0 X1 Y1 LO HI
[$_, $gf, $sf, $X0, $Y0, $X1, $Y1, $lo, $hi] = $argv; $g = file_get_contents($gf); $im = imagecreatefrompng($sf); $lo = hexdec($lo); $hi = hexdec($hi);
function tile($g, $u) { $px = []; for ($y = 0; $y < 8; $y++) { $b = unpack('C4', substr($g, $u * 64 + $y * 8, 4));
  for ($x = 0; $x < 8; $x++) { $bit = 7 - $x; $px[] = ((($b[4] >> $bit) & 1) << 3) | ((($b[3] >> $bit) & 1) << 2) | ((($b[2] >> $bit) & 1) << 1) | (($b[1] >> $bit) & 1); } } return $px; }
$T = []; for ($u = $lo; $u < $hi; $u++) { $px = tile($g, $u); if (count(array_unique($px)) >= 2) $T[$u] = $px; }
function cellhits($T, $im, $sx, $sy) { $h = []; $scr = []; for ($i = 0; $i < 64; $i++) $scr[$i] = imagecolorat($im, $sx + ($i & 7), $sy + ($i >> 3));
  if (count(array_unique($scr)) < 2) return null;
  foreach ($T as $u => $px) { $m = []; $ok = true; for ($i = 0; $i < 64; $i++) { $p = $px[$i]; $c = $scr[$i]; if (isset($m[$p])) { if ($m[$p] !== $c) { $ok = false; break; } } else $m[$p] = $c; } if ($ok) $h[] = $u; } return $h; }
$best = null;
for ($oy = 0; $oy < 8; $oy++) for ($ox = 0; $ox < 8; $ox++) { $uniq = 0; $grid = [];
  for ($y = $Y0 - 8 + $oy; $y + 8 <= $Y1 + 9; $y += 8) { $row = []; for ($x = $X0 - 8 + $ox; $x + 8 <= $X1 + 9; $x += 8) { $h = cellhits($T, $im, $x, $y);
      if ($h === null) $row[] = '.'; elseif (count($h) == 1) { $uniq++; $row[] = sprintf('%X', $h[0] - 0x20000); } elseif (count($h) == 0) $row[] = '-'; else $row[] = '*' . count($h); }
    $grid[] = sprintf("y=%3d x0=%3d: ", $y, $X0 - 8 + $ox) . implode(' ', $row); }
  if (!$best || $uniq > $best[0]) $best = [$uniq, $grid]; }
echo "unique=$best[0]\n" . implode("\n", $best[1]) . "\n";
