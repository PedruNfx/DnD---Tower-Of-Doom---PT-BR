<?php
// Many-to-one pen->colour matching of 8x8 tiles against a screenshot.
// mode "locate": php shotfind2.php gfx shot locate UNIT_HEX         -> screen positions where that tile (left half) fits
// mode "grid":   php shotfind2.php gfx shot grid X0 Y0 W H LO HI    -> for each 8x8 cell of the region (grid anchored at X0,Y0), matching units
$g = file_get_contents($argv[1]); $im = imagecreatefrompng($argv[2]); $mode = $argv[3];
function tile($g, $u) { $px = []; for ($y = 0; $y < 8; $y++) { $b = unpack('C4', substr($g, $u * 64 + $y * 8, 4));
  for ($x = 0; $x < 8; $x++) { $bit = 7 - $x; $px[] = ((($b[4] >> $bit) & 1) << 3) | ((($b[3] >> $bit) & 1) << 2) | ((($b[2] >> $bit) & 1) << 1) | (($b[1] >> $bit) & 1); } } return $px; }
function fits($px, $im, $sx, $sy, &$ncol) { $m = []; $cols = []; for ($i = 0; $i < 64; $i++) { $c = imagecolorat($im, $sx + ($i & 7), $sy + ($i >> 3)); $p = $px[$i];
  if (isset($m[$p])) { if ($m[$p] !== $c) return false; } else $m[$p] = $c; $cols[$c] = 1; } $ncol = count($cols); return count($m) >= 2; }
if ($mode === 'locate') { $px = tile($g, hexdec($argv[4])); $W = imagesx($im); $H = imagesy($im);
  for ($y = 0; $y + 8 <= $H; $y++) for ($x = 0; $x + 8 <= $W; $x++) { $n = 0; if (fits($px, $im, $x, $y, $n) && $n >= 2) echo "$x,$y\n"; } }
else { [$x0, $y0, $w, $h, $lo, $hi] = array_slice($argv, 4); $lo = hexdec($lo); $hi = hexdec($hi); $cache = [];
  for ($u = $lo; $u < $hi; $u++) { $cache[$u] = tile($g, $u); }
  for ($cy = $y0; $cy + 8 <= $y0 + $h; $cy += 8) { $row = [];
    for ($cx = $x0; $cx + 8 <= $x0 + $w; $cx += 8) { $hits = [];
      foreach ($cache as $u => $px) { $n = 0; $k = count(array_unique($px)); if ($k < 3) continue; if (fits($px, $im, $cx, $cy, $n) && $n >= 2) $hits[] = sprintf('%X', $u - 0x20000); }
      $row[] = count($hits) ? (count($hits) > 3 ? '*' : implode(',', $hits)) : '-'; }
    echo "y=$cy: " . implode(' ', $row) . "\n"; } }
