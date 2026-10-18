# dump a run of 16x16 sprite tiles as one strip: '.' transparent, pen hex otherwise; with column ruler
my ($gfx, @t) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
my $W = 16 * @t; print '   ', join('', map { int($_ / 10) % 10 } 0 .. $W - 1), "\n   ", join('', map { $_ % 10 } 0 .. $W - 1), "\n";
for my $y (0 .. 15) { my $s = sprintf('%2d ', $y);
  for my $t (map { hex } @t) { my @b = unpack('C8', substr($g, $t * 128 + $y * 8, 8));
    for my $x (0 .. 15) { my $q = $x < 8 ? 0 : 4; my $bit = 7 - ($x % 8);
      my $p = ((($b[$q + 3] >> $bit) & 1) << 3) | ((($b[$q + 2] >> $bit) & 1) << 2) | ((($b[$q + 1] >> $bit) & 1) << 1) | (($b[$q] >> $bit) & 1);
      $s .= $p == 15 ? '.' : sprintf('%X', $p); } } print "$s\n"; }
