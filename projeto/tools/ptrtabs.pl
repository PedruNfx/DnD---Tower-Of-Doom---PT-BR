# Find tables of 32-bit pointers to text strings (target preceded by 0x4040 terminator and containing font chars)
my ($file) = @ARGV;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>; my $n = length $d;
sub istext { my $v = shift; return 0 if $v & 1 || $v < 4 || $v >= $n - 16;
  return 0 unless substr($d, $v - 2, 2) eq "\x40\x40" || 1;
  my @w = unpack('n8', substr($d, $v, 16)); my $c = grep { ($_ >> 8) == 0x14 && ($_ & 0xFF) >= 0x40 } @w; return $c >= 2; }
my @runs; my ($start, $cnt) = (-1, 0);
for (my $i = 0; $i < $n - 4; $i += 2) {
  my $v = unpack('N', substr($d, $i, 4));
  if (istext($v)) { if ($start < 0 || ($i - $start) != $cnt * 4) { push @runs, [$start, $cnt] if $cnt >= 2; ($start, $cnt) = ($i, 0) } $cnt++; $i += 2; }
}
push @runs, [$start, $cnt] if $cnt >= 2;
for my $r (@runs) { my ($s, $c) = @$r; printf "%06X x%-3d %s\n", $s, $c, join(' ', map { sprintf '%06X', unpack('N', substr($d, $s + 4*$_, 4)) } 0 .. ($c > 12 ? 11 : $c - 1)); }
