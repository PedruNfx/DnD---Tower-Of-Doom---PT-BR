# dump the PLAYER SELECT sign (28x4 scroll1 tiles) as pens: signdump.pl gfx [x0 x1]
my ($gfx, $x0, $x1) = @ARGV; $x0 //= 0; $x1 //= 223; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
sub code { my ($c, $r) = @_; return ($c < 6 ? 0x160A + $c : $c < 22 ? 0x1680 + $c - 6 : 0x1700 + $c - 22) + 0x10 * $r; }
sub px { my ($x, $y) = @_; my $u = 0x20000 + code(int($x / 8), int($y / 8)); my @b = unpack('C4', substr($g, $u * 64 + ($y % 8) * 8, 4)); my $bit = 7 - $x % 8;
  return ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1); }
print '   ', join('', map { $_ % 10 } $x0 .. $x1), "\n";
for my $y (0 .. 31) { printf "%2d %s\n", $y, join '', map { sprintf '%X', px($_, $y) } $x0 .. $x1; }
