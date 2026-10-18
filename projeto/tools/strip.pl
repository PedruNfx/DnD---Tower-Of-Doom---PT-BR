# Print a horizontal strip of 8x8 tiles (left halves) as pen characters: strip.pl gfx first_code_hex ncodes
my ($gfx, $c0, $n) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>; $c0 = hex $c0;
for my $y (0 .. 7) { my $s = ''; for my $k (0 .. $n - 1) { my $u = 0x20000 + $c0 + $k; my @b = unpack('C4', substr($g, $u * 64 + $y * 8, 4));
  for my $x (0 .. 7) { my $bit = 7 - $x; my $p = ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1); $s .= $p == 15 ? '.' : sprintf('%X', $p); } $s .= '|'; } print "$s\n"; }
