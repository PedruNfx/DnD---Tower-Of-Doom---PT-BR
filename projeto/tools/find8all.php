<?php
// Global 8x8 half-tile search (many-to-one pen->colour) for a screen window at all 64 offsets.
// usage: php find8all.php gfx shot X Y [skiplo skiphi]
$g = file_get_contents($argv[1]); $im = imagecreatefrompng($argv[2]); $X = (int)$argv[3]; $Y = (int)$argv[4];
$slo = isset($argv[5]) ? hexdec($argv[5]) : -1; $shi = isset($argv[6]) ? hexdec($argv[6]) : -1; $n = intdiv(strlen($g), 64);
// pre-decode all halves once
$T = []; for ($u = 0; $u < $n; $u++) { if ($u >= $slo && $u < $shi) continue; foreach ([0, 4] as $h) { $px = '';
  for ($y = 0; $y < 8; $y++) { $b = unpack('C4', substr($g, $u * 64 + $y * 8 + $h, 4)); for ($x = 0; $x < 8; $x++) { $bit = 7 - $x;
    $px .= chr(((($b[4] >> $bit) & 1) << 3) | ((($b[3] >> $bit) & 1) << 2) | ((($b[2] >> $bit) & 1) << 1) | (($b[1] >> $bit) & 1)); } }
  if (count(array_unique(str_split($px))) >= 3) $T[sprintf('%05X%s', $u, $h ? 'R' : 'L')] = $px; } }
fwrite(STDERR, count($T) . " candidate halves\n");
for ($dy = 0; $dy < 8; $dy++) for ($dx = 0; $dx < 8; $dx++) { $scr = []; for ($i = 0; $i < 64; $i++) $scr[$i] = imagecolorat($im, $X + $dx + ($i & 7), $Y + $dy + ($i >> 3));
  if (count(array_unique($scr)) < 3) continue; $hits = [];
  foreach ($T as $k => $px) { $m = []; $ok = true; for ($i = 0; $i < 64; $i++) { $p = ord($px[$i]); $c = $scr[$i]; if (isset($m[$p])) { if ($m[$p] !== $c) { $ok = false; break; } } else $m[$p] = $c; }
    if ($ok) { $hits[] = $k; if (count($hits) > 5) break; } }
  if ($hits) echo "offset ($dx,$dy): " . implode(' ', $hits) . "\n"; }
