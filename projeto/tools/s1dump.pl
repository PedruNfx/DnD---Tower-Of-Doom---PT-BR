# dump scroll1 8x8 tiles (left half) side by side as pens: s1dump.pl gfx code_hex...
my ($gfx, @c) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
print '   ', join('', map { sprintf('%-8s', sprintf('%04X', hex $_)) } @c), "\n";
for my $y (0 .. 7) { my $s = sprintf('%2d ', $y);
  for my $c (map { 0x20000 + hex } @c) { my @b = unpack('C4', substr($g, $c * 64 + $y * 8, 4));
    for my $x (0 .. 7) { my $bit = 7 - $x; my $p = ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1);
      $s .= $p == 15 ? '.' : sprintf('%X', $p); } } print "$s\n"; }
