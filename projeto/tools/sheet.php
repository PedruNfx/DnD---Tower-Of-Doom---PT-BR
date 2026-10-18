<?php
// contact sheet: php sheet.php out.png cols file1 file2 ...
$out = $argv[1]; $cols = (int)$argv[2]; $files = array_slice($argv, 3);
$w = 384; $h = 224; $rows = (int)ceil(count($files) / $cols);
$img = imagecreatetruecolor($cols * ($w + 4), $rows * ($h + 4));
imagefill($img, 0, 0, imagecolorallocate($img, 255, 0, 255));
foreach ($files as $i => $f) { $s = imagecreatefrompng($f); imagecopy($img, $s, ($i % $cols) * ($w + 4), intdiv($i, $cols) * ($h + 4), 0, 0, imagesx($s), imagesy($s));
  imagestring($img, 3, ($i % $cols) * ($w + 4) + 2, intdiv($i, $cols) * ($h + 4) + 2, (string)$i, imagecolorallocate($img, 255, 255, 0)); }
imagepng($img, $out);
