# decode 0x14xx dialogue-font strings in a range: strdump.pl prog lo hi
require "$ENV{T}/tbl.pl"; my %d = %Tbl::dec;
my ($f, $lo, $hi) = @ARGV; open my $h, '<:raw', $f or die; local $/; my $p = <$h>; ($lo, $hi) = map { hex } $lo, $hi;
my $s = ''; my $st;
for (my $a = $lo; $a < $hi; $a += 2) { my $w = unpack('n', substr($p, $a, 2));
  if ($w == 0x4040) { printf "%06X-%06X (%2d) '%s'\n", $st // $a, $a, length $s, $s if length $s; $s = ''; undef $st; next; }
  my $c = $w == 0x2F2F ? '/' : ($w >> 8) == 0x14 && exists $d{$w & 0xFF} ? $d{$w & 0xFF} : sprintf('{%04X}', $w); $st //= $a; $s .= $c; }
