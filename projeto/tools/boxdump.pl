# Dump a box canvas (rows of tile codes, left halves) as pen characters. usage: boxdump.pl gfx "c,c,c;c,c,c;..."
my ($gfx, $spec) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
my @rows = map { [ map { hex } split /,/ ] } split /;/, $spec;
sub px { my ($u, $y, $x) = @_; my @b = unpack('C4', substr($g, $u * 64 + $y * 8, 4)); my $bit = 7 - $x;
  return ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1); }
my $W = 8 * @{ $rows[0] }; print '    ', join('', map { $_ % 10 } 0 .. $W - 1), "\n";
for my $r (0 .. $#rows) { for my $y (0 .. 7) { my $s = sprintf('%3d ', $r * 8 + $y);
  for my $c (@{ $rows[$r] }) { for my $x (0 .. 7) { my $p = px(0x20000 + $c, $y, $x); $s .= $p == 15 ? ' ' : sprintf('%X', $p); } } print "$s\n"; } }
