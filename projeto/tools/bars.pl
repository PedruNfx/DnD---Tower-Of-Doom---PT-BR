# print the text band (canvas rows 5..9) of item label bars: rows c0 (top) and c0+0x10 (bottom), 16 tiles wide
my ($gfx, @rows) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
sub px { my ($u, $y, $x) = @_; my @b = unpack('C4', substr($g, $u * 64 + $y * 8, 4)); my $bit = 7 - $x;
  return ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1); }
for my $r (@rows) { my $c0 = hex $r; print "== $r\n   ", join('', map { $_ % 10 } 0 .. 127), "\n";
  for my $y (4 .. 10) { my $tr = $y < 8 ? $c0 : $c0 + 0x10; my $yy = $y % 8; my $s = '';
    for my $x (0 .. 127) { my $p = px(0x20000 + $tr + int($x / 8), $yy, $x % 8); $s .= $p == 9 ? '#' : '.'; } printf "%2d %s\n", $y, $s; } }
