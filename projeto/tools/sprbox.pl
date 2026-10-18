# dump a sprite-tile box (rows of 16x16 tile codes) as pens: sprbox.pl gfx "t,t,t;t,t,t"
my ($gfx, $spec) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
my @rows = map { [ map { hex } split /,/ ] } split /;/, $spec;
print '    ', join('', map { $_ % 10 } 0 .. 16 * @{ $rows[0] } - 1), "\n";
for my $r (0 .. $#rows) { for my $y (0 .. 15) { my $s = sprintf('%3d ', $r * 16 + $y);
  for my $t (@{ $rows[$r] }) { my @b = unpack('C8', substr($g, $t * 128 + $y * 8, 8));
    for my $x (0 .. 15) { my $q = $x < 8 ? 0 : 4; my $bit = 7 - ($x % 8);
      my $p = ((($b[$q + 3] >> $bit) & 1) << 3) | ((($b[$q + 2] >> $bit) & 1) << 2) | ((($b[$q + 1] >> $bit) & 1) << 1) | (($b[$q] >> $bit) & 1);
      $s .= $p == 15 ? ' ' : sprintf('%X', $p); } } print "$s\n"; } }
