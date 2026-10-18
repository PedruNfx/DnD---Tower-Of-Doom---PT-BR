# Find code references (absolute long or PC-relative d16 / d8 index) to target addresses in the decrypted image.
# usage: xref.pl dec.bin target_hex [target_hex...] [-range lo_hex hi_hex]  (a range matches any target inside it)
use strict; use warnings;
my ($file, @t) = @ARGV; my ($lo, $hi);
if (@t >= 3 && $t[-3] eq '-range') { ($lo, $hi) = map { hex } @t[-2, -1]; splice @t, -3; }
my %want = map { hex($_) => 1 } @t;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>; my $n = length $d;
my $hit = sub { my $v = shift; return 1 if $want{$v}; return defined $lo && $v >= $lo && $v < $hi; };
for (my $i = 0; $i + 4 <= $n && $i < 0x200000; $i += 2) {
  my $w = unpack('n', substr($d, $i, 2)); my $x = unpack('n', substr($d, $i + 2, 2));
  if (($w & 0x3F) == 0x3A || ($w & 0x0FC0) == 0x0E80 ) {   # source EA d16(pc)  (or dest for some forms)
    my $t = $i + 2 + ($x >= 0x8000 ? $x - 0x10000 : $x); printf "%06X: %04X %04X  d16(pc) -> %06X\n", $i, $w, $x, $t if $hit->($t); }
  if (($w & 0x3F) == 0x3B) { my $t = $i + 2 + (($x & 0xFF) >= 0x80 ? ($x & 0xFF) - 0x100 : ($x & 0xFF)); printf "%06X: %04X %04X  d8(pc,x) -> %06X\n", $i, $w, $x, $t if $hit->($t); }
  if ($i + 6 <= $n) { my $l = unpack('N', substr($d, $i + 2, 4)); printf "%06X: %04X %08X  abs.l -> %06X\n", $i, $w, $l, $l if $hit->($l) && (($w & 0x3F) == 0x39 || ($w & 0x0FC0) == 0x03C0 || ($w & 0xF1FF) == 0x203C || ($w & 0xF1FF) == 0x207C || $w == 0x2F3C || $w == 0x4879); }
}
