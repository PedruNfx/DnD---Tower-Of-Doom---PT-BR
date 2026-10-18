# print ink masks of a strip of scroll1 tiles (left halves): inkmask.pl gfx inkpens rows codes...
my ($gfx, $ink, $rows, @c) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>; my %ink = map { hex($_) => 1 } split //, $ink; my ($r0, $r1) = split /-/, $rows;
print '   ', join('', map { $_ % 10 } 0 .. 8 * @c - 1), "\n";
for my $y ($r0 .. $r1) { my $s = sprintf('%2d ', $y);
  for my $c (map { 0x20000 + hex } @c) { my @b = unpack('C4', substr($g, $c * 64 + $y * 8, 4));
    for my $x (0 .. 7) { my $bit = 7 - $x; my $p = ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1);
      $s .= $ink{$p} ? '#' : '.'; } } print "$s\n"; }
