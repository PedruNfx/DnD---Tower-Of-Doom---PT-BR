# Print 8x16 glyph (tile c on top, c+0x10 below; left half only) for given text words
my ($gfx, @words) = @ARGV;
open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
sub px { my ($b, $y, $x) = @_; my @by = unpack('C4', substr($g, $b * 64 + $y * 8, 4)); my $bit = 7 - $x;
  return ((($by[3] >> $bit) & 1) << 3) | ((($by[2] >> $bit) & 1) << 2) | ((($by[1] >> $bit) & 1) << 1) | (($by[0] >> $bit) & 1); }
my @out;
for my $w (@words) { my $c = 0x20000 + hex $w; my @rows = (sprintf("%-8s", $w));
  for my $y (0 .. 15) { my $b = $c + ($y >= 8 ? 0x10 : 0); my $s = '';
    for my $x (0 .. 7) { my $p = px($b, $y % 8, $x); $s .= $p == 15 ? '.' : sprintf('%X', $p); } push @rows, $s; }
  push @out, \@rows; }
for my $i (0 .. 16) { print join('  ', map { $_->[$i] } @out), "\n"; }
