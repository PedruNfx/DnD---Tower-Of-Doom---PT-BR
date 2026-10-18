# Print 8x8 glyphs (left half) for tile codes (unit = 0x20000 + code)
my ($gfx, @codes) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
my @out; for my $c (@codes) { my $b = 0x20000 + hex $c; my @rows = (sprintf('%-8s', $c));
  for my $y (0 .. 7) { my @by = unpack('C4', substr($g, $b * 64 + $y * 8, 4)); my $s = '';
    for my $x (0 .. 7) { my $bit = 7 - $x; my $p = ((($by[3] >> $bit) & 1) << 3) | ((($by[2] >> $bit) & 1) << 2) | ((($by[1] >> $bit) & 1) << 1) | (($by[0] >> $bit) & 1); $s .= $p == 15 ? '.' : sprintf('%X', $p); } push @rows, $s; }
  push @out, \@rows; }
for my $i (0 .. 8) { print join('  ', map { $_->[$i] } @out), "\n"; }
