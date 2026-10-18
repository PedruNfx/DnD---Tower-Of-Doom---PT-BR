<?php
// Find gfx 8x8 half-tiles whose pixel pattern matches 8x8 blocks of a screenshot region (up to colour renaming).
// usage: php shotfind.php gfx.bin shot.png x y w h unit_lo_hex unit_hi_hex
[$_, $gfxf, $shot, $rx, $ry, $rw, $rh, $lo, $hi] = $argv;
$g = file_get_contents($gfxf); $lo = hexdec($lo); $hi = hexdec($hi);
function canon($a) { $m = []; $k = 0; $o = ''; foreach ($a as $v) { if (!isset($m[$v])) $m[$v] = $k++; $o .= chr(65 + $m[$v]); } return [$o, $k]; }
// index
$idx = [];
for ($u = $lo; $u < $hi; $u++) {
  $base = $u * 64; $L = []; $R = [];
  for ($y = 0; $y < 8; $y++) { $b = unpack('C8', substr($g, $base + $y * 8, 8));
    for ($x = 0; $x < 8; $x++) { $bit = 7 - $x;
      $L[] = ((($b[4] >> $bit) & 1) << 3) | ((($b[3] >> $bit) & 1) << 2) | ((($b[2] >> $bit) & 1) << 1) | (($b[1] >> $bit) & 1);
      $R[] = ((($b[8] >> $bit) & 1) << 3) | ((($b[7] >> $bit) & 1) << 2) | ((($b[6] >> $bit) & 1) << 1) | (($b[5] >> $bit) & 1); } }
  foreach ([['L', $L], ['R', $R]] as [$h, $px]) { [$c, $k] = canon($px); if ($k >= 3) { $idx[$c][] = sprintf('%05X%s', $u, $h); } }
}
fwrite(STDERR, "indexed " . count($idx) . " patterns\n");
$im = imagecreatefrompng($shot); $found = [];
for ($oy = 0; $oy < 8; $oy++) for ($ox = 0; $ox < 8; $ox++) {
  for ($by = $ry + $oy; $by + 8 <= $ry + $rh; $by += 8) for ($bx = $rx + $ox; $bx + 8 <= $rx + $rw; $bx += 8) {
    $px = []; for ($y = 0; $y < 8; $y++) for ($x = 0; $x < 8; $x++) $px[] = imagecolorat($im, $bx + $x, $by + $y);
    [$c, $k] = canon($px); if ($k < 3 || !isset($idx[$c])) continue;
    $found[] = sprintf("block (%d,%d) -> %s", $bx, $by, implode(' ', array_slice($idx[$c], 0, 6)));
  } }
echo implode("\n", $found), "\n";
