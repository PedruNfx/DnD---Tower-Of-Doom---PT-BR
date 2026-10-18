# CPS2 opcode decryption (port of MAME capcom/cps2crypt.cpp). S-box tables are parsed from that file.
# usage: cps2dec.pl <cps2crypt.cpp> <prog.bin (big-endian words)> <out dec.bin> <key0_hex> <key1_hex> <upper_hex>
use strict; use warnings;
my ($src, $in, $out, $k0, $k1, $upper) = @ARGV; ($k0, $k1, $upper) = map { hex } ($k0, $k1, $upper);
open my $sh, '<', $src or die; local $/; my $cpp = <$sh>; close $sh;
sub BIT { ($_[0] >> $_[1]) & 1 }

# ---- parse sbox tables ----
my %boxes;
while ($cpp =~ /const sbox (fn[12]_r[1-4]_boxes)\[4\] =\s*\{(.*?)\n\};/sg) {
  my ($name, $body) = ($1, $2); my @b;
  while ($body =~ /\{\s*\/\/[^\n]*\n\s*\{([^}]*)\},\s*\{([^}]*)\},\s*\{([^}]*)\}\s*\}/sg) {
    my @t = map { int } grep { /\S/ } split /[,\s]+/, $1; my @i = map { int } grep { /\S/ } split /[,\s]+/, $2; my @o = map { int } grep { /\S/ } split /[,\s]+/, $3;
    die "bad box $name" unless @t == 64 && @i == 6 && @o == 2; push @b, [\@t, \@i, \@o]; }
  die "bad $name: " . scalar(@b) unless @b == 4; $boxes{$name} = \@b; }
die "missing boxes\n" unless keys %boxes == 8;
sub optimise { my $box = shift; my ($t, $in, $o) = @$box; my (@lk, @out);
  for my $v (0 .. 255) { my $r = 0; for my $i (0 .. 5) { $r |= BIT($v, $in->[$i]) << $i if $in->[$i] >= 0; } $lk[$v] = $r; }
  for my $i (0 .. 63) { my $x = $t->[$i]; my $m = 0; $m |= 1 << $o->[0] if $x & 1; $m |= 1 << $o->[1] if $x & 2; $out[$i] = $m; }
  return [\@lk, \@out]; }
my %ob; for my $n (keys %boxes) { $ob{$n} = [ map { optimise($_) } @{ $boxes{$n} } ]; }
sub fn { my ($in, $sb, $key) = @_; my $r = 0;
  for my $k (0 .. 3) { my ($lk, $o) = @{ $sb->[$k] }; $r |= $o->[ $lk->[$in] ^ (($key >> (6 * $k)) & 0x3f) ]; } return $r; }

# ---- bit tables ----
sub grab { my ($name, $n) = @_; $cpp =~ /\Q$name\E\[$n\]\s*=\s*\{([^}]*)\}/s or die "no $name"; return [ map { int } grep { /\S/ } split /[,\s]+/, $1 ]; }
my $g1A = grab('fn1_groupA', 8); my $g1B = grab('fn1_groupB', 8); my $g2A = grab('fn2_groupA', 8); my $g2B = grab('fn2_groupB', 8);
my ($e1) = $cpp =~ /void expand_1st_key.*?bits\[96\]\s*=\s*\{([^}]*)\}/s; my @e1 = map { int } grep { /\S/ } split /[,\s]+/, $e1;
my ($e2) = $cpp =~ /void expand_2nd_key.*?bits\[96\]\s*=\s*\{([^}]*)\}/s; my @e2 = map { int } grep { /\S/ } split /[,\s]+/, $e2;
my ($es) = $cpp =~ /void expand_subkey.*?bits\[64\]\s*=\s*\{([^}]*)\}/s; my @es = map { int } grep { /\S/ } split /[,\s]+/, $es;
die "bad tables" unless @e1 == 96 && @e2 == 96 && @es == 64;

sub expand { my ($bits, $src) = @_; my @d = (0, 0, 0, 0); for my $i (0 .. 95) { $d[int($i / 24)] |= BIT($src->[int($bits->[$i] / 32)], $bits->[$i] % 32) << ($i % 24); } return @d; }
# feistel with precomputed permutations
sub mkperm { my ($A, $B) = @_; my (@lA, @lB, @oA, @oB);
  for my $v (0 .. 65535) { } # unused
  return; }
sub feistel { my ($val, $A, $B, $sb, $k) = @_;
  my ($l, $r) = (0, 0); for my $i (0 .. 7) { $l |= BIT($val, $B->[$i]) << $i; $r |= BIT($val, $A->[$i]) << $i; }
  $l ^= fn($r, $sb->[0], $k->[0]); $r ^= fn($l, $sb->[1], $k->[1]); $l ^= fn($r, $sb->[2], $k->[2]); $r ^= fn($l, $sb->[3], $k->[3]);
  my $res = 0; for my $i (0 .. 7) { $res |= BIT($l, $i) << $A->[$i]; $res |= BIT($r, $i) << $B->[$i]; } return $res; }
# fast fn2 path: precompute input split tables for fn2 groups
my (@hiB, @loB, @hiA, @loA);   # l = hiB[val>>8] | loB[val&255]
for my $v (0 .. 255) { my ($a1, $b1, $a2, $b2) = (0, 0, 0, 0);
  for my $i (0 .. 7) { $b1 |= BIT($v << 8, $g2B->[$i]) << $i; $b2 |= BIT($v, $g2B->[$i]) << $i; $a1 |= BIT($v << 8, $g2A->[$i]) << $i; $a2 |= BIT($v, $g2A->[$i]) << $i; }
  ($hiB[$v], $loB[$v], $hiA[$v], $loA[$v]) = ($b1, $b2, $a1, $a2); }
my (@outL, @outR); for my $v (0 .. 255) { my ($x, $y) = (0, 0); for my $i (0 .. 7) { $x |= BIT($v, $i) << $g2A->[$i]; $y |= BIT($v, $i) << $g2B->[$i]; } $outL[$v] = $x; $outR[$v] = $y; }

my @master = ($k0, $k1);
my @key1 = expand(\@e1, \@master);
$key1[0] ^= BIT($key1[0], 1) << 4; $key1[0] ^= BIT($key1[0], 2) << 5; $key1[0] ^= BIT($key1[0], 8) << 11;
$key1[1] ^= BIT($key1[1], 0) << 5; $key1[1] ^= BIT($key1[1], 8) << 11;
$key1[2] ^= BIT($key1[2], 1) << 5; $key1[2] ^= BIT($key1[2], 8) << 11;
my @sb1 = map { $ob{"fn1_r${_}_boxes"} } 1 .. 4; my @sb2 = map { $ob{"fn2_r${_}_boxes"} } 1 .. 4;

open my $ih, '<:raw', $in or die; my @rom = unpack('n*', scalar <$ih>); close $ih;
my @dec = @rom; my $limit = $upper / 2;
for my $i (0 .. 0xFFFF) {
  my $seed = feistel($i, $g1A, $g1B, \@sb1, \@key1);
  my @sub = (0, 0); for my $j (0 .. 63) { $sub[int($j / 32)] |= BIT($seed, $es[$j]) << ($j % 32); }
  $sub[0] ^= $master[0]; $sub[1] ^= $master[1];
  my @k2 = expand(\@e2, \@sub);
  $k2[0] ^= BIT($k2[0], 0) << 5; $k2[0] ^= BIT($k2[0], 6) << 11; $k2[1] ^= BIT($k2[1], 0) << 5; $k2[1] ^= BIT($k2[1], 1) << 4;
  $k2[2] ^= BIT($k2[2], 2) << 5; $k2[2] ^= BIT($k2[2], 3) << 4; $k2[2] ^= BIT($k2[2], 7) << 11; $k2[3] ^= BIT($k2[3], 1) << 5;
  for (my $a = $i; $a < @rom; $a += 0x10000) {
    next unless $a <= $limit;   # lower limit is 0
    my $v = $rom[$a]; my $l = $hiB[$v >> 8] | $loB[$v & 255]; my $r = $hiA[$v >> 8] | $loA[$v & 255];
    $l ^= fn($r, $sb2[0], $k2[0]); $r ^= fn($l, $sb2[1], $k2[1]); $l ^= fn($r, $sb2[2], $k2[2]); $r ^= fn($l, $sb2[3], $k2[3]);
    $dec[$a] = $outL[$l] | $outR[$r]; }
  print STDERR sprintf("\r%d%%", $i * 100 / 0x10000) if ($i & 0xFFF) == 0;
}
open my $oh, '>:raw', $out or die; print $oh pack('n*', @dec); close $oh; print STDERR "\ndone\n";
